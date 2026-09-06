//! Sharing photos over a Firefox Send server.
//!
//! One call does the whole job: [`ffsend_upload_file`] resolves to the share URL, or fails with a
//! typed [`FfSendUploadError`]. Progress arrives on a separate sink that carries nothing but
//! progress, so the completion of the upload is never something the caller has to infer from the
//! stream.

use chrono::{DateTime, Duration, Utc};
use flutter_rust_bridge::DartFnFuture;

use crate::utils::ffsend_client;

/// Uploads a file and returns the URL it can be downloaded from.
pub async fn ffsend_upload_file(
    request: FfSendUploadRequest,
    on_progress: impl Fn(FfSendUploadProgress) -> DartFnFuture<()> + Send + Sync + 'static,
) -> Result<FfSendUploadResult, FfSendUploadError> {
    ffsend_client::upload_file(request, on_progress).await
}

/// What to upload, and how long it may take.
pub struct FfSendUploadRequest {
    /// Base URL of the Send server, for example `https://send.vis.ee/`.
    pub host_url: String,

    /// Absolute path of the file to upload.
    pub file_path: String,

    /// The name the file is downloaded under. Its extension decides the reported MIME type.
    pub download_filename: String,

    /// How often the file may be downloaded before the server deletes it. Send defaults to once.
    pub max_downloads: Option<u8>,

    /// How long the file stays available. Send defaults to a day.
    pub expires_after: Option<Duration>,

    /// Budget for connecting to the server and for each of the two handshake messages.
    pub control_timeout: Duration,

    /// Budget for transferring the encrypted file.
    pub transfer_timeout: Duration,
}

/// How far along an upload is. Sent repeatedly while the file is transferred.
pub struct FfSendUploadProgress {
    pub transferred_bytes: u64,

    /// Size of the file being uploaded. Known before the first byte is sent.
    pub total_bytes: u64,
}

/// A file that was uploaded successfully.
pub struct FfSendUploadResult {
    /// The share URL including its secret fragment. This is what the QR code encodes.
    pub download_url: String,

    /// When the server will delete the file.
    pub expires_at: DateTime<Utc>,

    /// Identifiers needed to delete the file before it expires.
    pub file_id: String,
    pub owner_token: String,
}

/// Why an upload did not produce a share URL.
///
/// Every variant carries a message that is safe to log; none of them contain the secret.
pub enum FfSendUploadError {
    /// The configured Send server URL could not be used.
    InvalidHostUrl(String),

    /// The photo could not be read from disk.
    FileNotReadable(String),

    /// The server could not be reached. Usually no internet, or a wrong host.
    Connect(String),

    /// The server refused the upload, for example because the file is too large.
    Rejected(String),

    /// The connection dropped part way through.
    Transfer(String),

    /// Encrypting the photo failed.
    Crypto(String),

    /// The upload ran past one of the configured timeouts.
    Timeout(String),
}
