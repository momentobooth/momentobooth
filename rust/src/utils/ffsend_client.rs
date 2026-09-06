//! Firefox Send v3 client.
//!
//! This is a direct implementation of the parts of the Send protocol MomentoBooth uses, replacing
//! the `ffsend-api` crate and the stack of unmaintained HTTP and websocket crates it depended on.
//! The wire format is verified against `ffsend-api` by the tests in [`ece`] and [`crypto`].

use std::{path::PathBuf, time::Duration};

use flutter_rust_bridge::DartFnFuture;

use crate::api::ffsend::{FfSendUploadError, FfSendUploadProgress, FfSendUploadRequest, FfSendUploadResult};

mod crypto;
mod ece;
mod protocol;

/// Uploads a file, calling `on_progress` while it runs.
///
/// Progress is reported in plaintext bytes, so it lines up with the size of the file on disk rather
/// than with the slightly larger ciphertext actually sent.
pub async fn upload_file(
    request: FfSendUploadRequest,
    on_progress: impl Fn(FfSendUploadProgress) -> DartFnFuture<()>,
) -> Result<FfSendUploadResult, FfSendUploadError> {
    let request = protocol::UploadRequest {
        host_url: request.host_url,
        file_path: PathBuf::from(request.file_path),
        download_filename: request.download_filename,
        max_downloads: request.max_downloads,
        expires_after: request.expires_after.map(to_std_duration),
        control_timeout: to_std_duration(request.control_timeout),
        transfer_timeout: to_std_duration(request.transfer_timeout),
    };

    let uploaded = protocol::upload(&request, |transferred_bytes, total_bytes| {
        on_progress(FfSendUploadProgress { transferred_bytes, total_bytes })
    })
    .await?;

    Ok(FfSendUploadResult {
        download_url: uploaded.download_url,
        expires_at: uploaded.expires_at.unwrap_or_else(chrono::Utc::now),
        file_id: uploaded.file_id,
        owner_token: uploaded.owner_token,
    })
}

/// Clamps a duration coming from the settings to something [`std::time::Duration`] can hold.
///
/// A negative or absurd value in the settings file should not panic the upload.
fn to_std_duration(duration: chrono::Duration) -> Duration {
    duration.to_std().unwrap_or(Duration::ZERO)
}

impl From<protocol::UploadError> for FfSendUploadError {
    fn from(error: protocol::UploadError) -> Self {
        use protocol::UploadError;

        match error {
            UploadError::InvalidHostUrl(detail) => Self::InvalidHostUrl(detail),
            UploadError::FileNotReadable(detail) => Self::FileNotReadable(detail),
            UploadError::Connect(detail) => Self::Connect(detail),
            UploadError::Rejected(detail) => Self::Rejected(detail),
            UploadError::Transfer(detail) => Self::Transfer(detail),
            UploadError::Crypto(detail) => Self::Crypto(detail),
            UploadError::Timeout(detail) => Self::Timeout(detail),
        }
    }
}
