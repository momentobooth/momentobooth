use chrono::Duration;
pub use ipp::model::PrinterState;
pub use ipp::model::JobState;

use crate::{frb_generated::StreamSink, utils::ffsend_client::{self, FfSendTransferProgress}};

pub fn ffsend_upload_file(host_url: String, file_path: String, download_filename: Option<String>, max_downloads: Option<u8>, expires_after_seconds: Option<u32>, update_sink: StreamSink<FfSendTransferProgress>, control_command_timeout: Duration, transfer_timeout: Duration) {
    ffsend_client::upload_file(host_url, file_path, download_filename, max_downloads, expires_after_seconds, update_sink, control_command_timeout.to_std().unwrap(), transfer_timeout.to_std().unwrap())
}

pub fn ffsend_delete_file(file_id: String) {
    ffsend_client::delete_file(file_id)
}
