//! The Firefox Send v3 upload protocol.
//!
//! Uploading is a single websocket exchange: a JSON frame describing the file, a JSON reply with
//! the share URL, then the ECE ciphertext as binary frames, a one byte footer, and a JSON
//! acknowledgement. The file itself is encrypted before it leaves this process; the server only
//! ever sees ciphertext and the derived authentication key.

use std::{path::{Path, PathBuf}, time::Duration};

use chrono::{DateTime, Utc};
use futures::{SinkExt, StreamExt};
use serde::{Deserialize, Serialize};
use serde_json::Value;
use tokio::{fs::File, io::AsyncReadExt, time::timeout};
use tokio_tungstenite::tungstenite::Message;
use url::Url;

use super::{crypto::{KeySet, Metadata}, ece::{EceEncrypter, SALT_LEN}};

/// Expiry Send applies when the client does not ask for one.
const DEFAULT_EXPIRE_SECONDS: u64 = 24 * 60 * 60;

/// What to upload, and how long it may take.
pub struct UploadRequest {
    pub host_url: String,
    pub file_path: PathBuf,
    pub download_filename: String,
    pub max_downloads: Option<u8>,
    pub expires_after: Option<Duration>,

    /// Budget for connecting and for each of the two JSON exchanges.
    pub control_timeout: Duration,

    /// Budget for sending the whole ciphertext.
    pub transfer_timeout: Duration,
}

/// A successfully uploaded file.
pub struct UploadedFile {
    /// The share URL including the secret fragment. This is what goes into the QR code.
    pub download_url: String,
    pub expires_at: Option<DateTime<Utc>>,

    /// Identifiers needed to delete the file before it expires.
    pub file_id: String,
    pub owner_token: String,
}

/// Uploads a file, awaiting `on_progress` with (plaintext bytes sent, total plaintext bytes).
pub async fn upload<F, Fut>(request: &UploadRequest, on_progress: F) -> Result<UploadedFile, UploadError>
where
    F: Fn(u64, u64) -> Fut,
    Fut: std::future::Future<Output = ()>,
{
    let host = Url::parse(&request.host_url).map_err(|e| UploadError::InvalidHostUrl(e.to_string()))?;
    let websocket_url = websocket_url(&host)?;

    let mut file = File::open(&request.file_path)
        .await
        .map_err(|e| UploadError::FileNotReadable(format!("{}: {e}", request.file_path.display())))?;
    let size = file
        .metadata()
        .await
        .map_err(|e| UploadError::FileNotReadable(format!("{}: {e}", request.file_path.display())))?
        .len();

    let keys = KeySet::generate().map_err(|e| UploadError::Crypto(e.to_string()))?;
    let metadata = Metadata::new(request.download_filename.clone(), mime_for(&request.download_filename).to_owned(), size);
    let file_info = FileInfo {
        time_limit: request.expires_after.map_or(DEFAULT_EXPIRE_SECONDS, |d| d.as_secs()),
        download_limit: request.max_downloads,
        metadata: keys.encrypt_metadata(&metadata).map_err(|e| UploadError::Crypto(e.to_string()))?,
        authorization: keys.authorization(),
        bearer: None,
    };

    let (mut socket, _) = timeout(request.control_timeout, tokio_tungstenite::connect_async(websocket_url.as_str()))
        .await
        .map_err(|_| UploadError::Timeout("connecting to the server".to_owned()))?
        .map_err(|e| UploadError::Connect(e.to_string()))?;

    // Announce the file and receive the share URL.
    let announcement = serde_json::to_string(&file_info).map_err(|e| UploadError::Crypto(e.to_string()))?;
    timeout(request.control_timeout, socket.send(Message::text(announcement)))
        .await
        .map_err(|_| UploadError::Timeout("sending the file information".to_owned()))?
        .map_err(|e| UploadError::Transfer(e.to_string()))?;

    let response = receive_json(&mut socket, request.control_timeout, "the upload response").await?;
    let response: UploadResponse = serde_json::from_value(response.clone())
        .map_err(|_| UploadError::Rejected(describe_server_error(&response)))?;

    // Send the ciphertext: the ECE header, then one binary frame per record, then the footer.
    // The whole transfer shares one budget, so a server that trickles along byte by byte still
    // fails instead of holding the upload open forever.
    let mut encrypter = EceEncrypter::new(keys.secret(), size, random_salt()?);
    let transfer = async {
        send_binary(&mut socket, encrypter.header()).await?;
        on_progress(0, size).await;

        let mut plaintext = vec![0u8; EceEncrypter::plaintext_record_size()];
        let mut sent = 0u64;
        while !encrypter.is_done() {
            let read = read_record(&mut file, &mut plaintext).await.map_err(|e| UploadError::FileNotReadable(e.to_string()))?;
            let record = encrypter.encrypt_record(&plaintext[..read]).map_err(|e| UploadError::Crypto(e.to_string()))?;

            send_binary(&mut socket, record).await?;
            sent += read as u64;
            on_progress(sent, size).await;
        }
        send_binary(&mut socket, vec![0]).await
    };
    timeout(request.transfer_timeout, transfer)
        .await
        .map_err(|_| UploadError::Timeout("sending the file".to_owned()))??;

    // The server acknowledges the upload only once it has stored everything.
    let status = receive_json(&mut socket, request.control_timeout, "the upload acknowledgement").await?;
    if status.get("ok").and_then(Value::as_bool) != Some(true) {
        return Err(UploadError::Rejected(describe_server_error(&status)));
    }

    let _ = socket.close(None).await;

    Ok(UploadedFile {
        download_url: format!("{}#{}", response.url, keys.secret_encoded()),
        expires_at: Some(Utc::now() + chrono::Duration::seconds(file_info.time_limit as i64)),
        file_id: response.id,
        owner_token: response.owner_token,
    })
}

/// Turns a Send host URL into the websocket endpoint used for uploading.
fn websocket_url(host: &Url) -> Result<Url, UploadError> {
    let mut url = host.join("api/ws").map_err(|e| UploadError::InvalidHostUrl(e.to_string()))?;

    let scheme = match url.scheme() {
        "https" | "wss" => "wss",
        "http" | "ws" => "ws",
        other => return Err(UploadError::InvalidHostUrl(format!("unsupported scheme '{other}'"))),
    };
    url.set_scheme(scheme).map_err(|_| UploadError::InvalidHostUrl("could not set the websocket scheme".to_owned()))?;

    Ok(url)
}

/// Fills `buffer` from `file`, stopping early only at end of file.
///
/// Every record but the last has to be exactly the record size, so a short read is not enough.
async fn read_record(file: &mut File, buffer: &mut [u8]) -> std::io::Result<usize> {
    let mut filled = 0;
    while filled < buffer.len() {
        match file.read(&mut buffer[filled..]).await? {
            0 => break,
            read => filled += read,
        }
    }
    Ok(filled)
}

async fn send_binary(socket: &mut WebSocket, payload: Vec<u8>) -> Result<(), UploadError> {
    socket.send(Message::binary(payload)).await.map_err(|e| UploadError::Transfer(e.to_string()))
}

async fn receive_json(socket: &mut WebSocket, budget: Duration, what: &str) -> Result<Value, UploadError> {
    loop {
        let message = timeout(budget, socket.next())
            .await
            .map_err(|_| UploadError::Timeout(format!("waiting for {what}")))?
            .ok_or_else(|| UploadError::Transfer(format!("the connection closed while waiting for {what}")))?
            .map_err(|e| UploadError::Transfer(e.to_string()))?;

        match message {
            Message::Text(text) => {
                return serde_json::from_str(&text).map_err(|_| UploadError::Rejected(format!("unreadable response: {text}")));
            }
            // Ping/pong and close frames may arrive at any time; anything else is a protocol error.
            Message::Ping(_) | Message::Pong(_) => continue,
            Message::Close(_) => return Err(UploadError::Transfer(format!("the server closed the connection while sending {what}"))),
            _ => return Err(UploadError::Rejected(format!("unexpected binary response while waiting for {what}"))),
        }
    }
}

/// Renders whatever the server sent instead of the expected response.
fn describe_server_error(value: &Value) -> String {
    match value.get("error") {
        Some(error) => format!("the server rejected the upload (error {error})"),
        None => format!("unexpected response from the server: {value}"),
    }
}

fn random_salt() -> Result<[u8; SALT_LEN], UploadError> {
    let mut salt = [0u8; SALT_LEN];
    getrandom::fill(&mut salt).map_err(|_| UploadError::Crypto("failed to generate a random salt".to_owned()))?;
    Ok(salt)
}

/// The MIME type Send should report on download.
fn mime_for(filename: &str) -> &'static str {
    match Path::new(filename).extension().and_then(|e| e.to_str()).unwrap_or_default().to_ascii_lowercase().as_str() {
        "jpg" | "jpeg" => "image/jpeg",
        "png" => "image/png",
        _ => "application/octet-stream",
    }
}

type WebSocket = tokio_tungstenite::WebSocketStream<tokio_tungstenite::MaybeTlsStream<tokio::net::TcpStream>>;

/// The frame that opens an upload.
#[derive(Serialize)]
struct FileInfo {
    #[serde(rename = "timeLimit")]
    time_limit: u64,
    #[serde(rename = "dlimit")]
    download_limit: Option<u8>,
    #[serde(rename = "fileMetadata")]
    metadata: String,
    authorization: String,
    /// Firefox Account authentication, which MomentoBooth never uses.
    bearer: Option<String>,
}

/// The server's reply to [`FileInfo`].
#[derive(Deserialize)]
struct UploadResponse {
    id: String,
    url: String,
    #[serde(rename = "ownerToken")]
    owner_token: String,
}

#[derive(Debug)]
pub enum UploadError {
    InvalidHostUrl(String),
    FileNotReadable(String),
    Connect(String),
    Rejected(String),
    Transfer(String),
    Crypto(String),
    Timeout(String),
}

impl std::fmt::Display for UploadError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            UploadError::InvalidHostUrl(detail) => write!(f, "invalid Send server URL: {detail}"),
            UploadError::FileNotReadable(detail) => write!(f, "could not read the file to upload: {detail}"),
            UploadError::Connect(detail) => write!(f, "could not connect to the Send server: {detail}"),
            UploadError::Rejected(detail) => write!(f, "{detail}"),
            UploadError::Transfer(detail) => write!(f, "the upload was interrupted: {detail}"),
            UploadError::Crypto(detail) => write!(f, "could not encrypt the file: {detail}"),
            UploadError::Timeout(detail) => write!(f, "timed out {detail}"),
        }
    }
}

impl std::error::Error for UploadError {}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn websocket_url_upgrades_the_scheme() {
        let cases = [
            ("https://send.example.com/", "wss://send.example.com/api/ws"),
            ("https://send.example.com", "wss://send.example.com/api/ws"),
            ("http://localhost:1443/", "ws://localhost:1443/api/ws"),
            ("https://example.com/send/", "wss://example.com/send/api/ws"),
        ];

        for (host, expected) in cases {
            let url = websocket_url(&Url::parse(host).expect("parse host")).expect("build websocket url");
            assert_eq!(url.as_str(), expected, "for host {host}");
        }
    }

    #[test]
    fn websocket_url_rejects_unsupported_schemes() {
        let url = Url::parse("ftp://send.example.com/").expect("parse host");
        assert!(matches!(websocket_url(&url), Err(UploadError::InvalidHostUrl(_))));
    }

    #[test]
    fn mime_is_derived_from_the_download_filename() {
        assert_eq!(mime_for("MomentoBooth 120000.jpg"), "image/jpeg");
        assert_eq!(mime_for("photo.JPEG"), "image/jpeg");
        assert_eq!(mime_for("photo.png"), "image/png");
        assert_eq!(mime_for("photo"), "application/octet-stream");
    }

    /// Uploads a real file to a real Send server and prints the share URL.
    ///
    /// Ignored by default because it needs a server. Run it against one with:
    ///
    /// ```sh
    /// FFSEND_TEST_HOST=https://send.example.com cargo test --lib round_trip -- --ignored --nocapture
    /// ```
    ///
    /// The printed URL is meant to be fed to the `ffsend` CLI, which decrypts and verifies the
    /// download independently of this implementation.
    #[test]
    #[ignore = "requires a reachable Send server"]
    fn round_trip_against_a_real_server() {
        let host = std::env::var("FFSEND_TEST_HOST").expect("set FFSEND_TEST_HOST");
        let path = PathBuf::from(std::env::var("FFSEND_TEST_FILE").expect("set FFSEND_TEST_FILE"));
        let filename = path.file_name().expect("file name").to_string_lossy().into_owned();

        let request = UploadRequest {
            host_url: host,
            file_path: path,
            download_filename: filename,
            max_downloads: Some(20),
            expires_after: Some(Duration::from_secs(3600)),
            control_timeout: Duration::from_secs(30),
            transfer_timeout: Duration::from_secs(120),
        };

        let runtime = tokio::runtime::Builder::new_current_thread().enable_all().build().expect("runtime");
        let uploaded = runtime
            .block_on(upload(&request, |sent, total| async move { println!("PROGRESS {sent}/{total}"); }))
            .expect("upload");

        println!("DOWNLOAD_URL {}", uploaded.download_url);
        println!("FILE_ID {}", uploaded.file_id);
        println!("EXPIRES_AT {:?}", uploaded.expires_at);
    }
}
