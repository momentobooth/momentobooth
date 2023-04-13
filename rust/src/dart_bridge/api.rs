use flutter_rust_bridge::{StreamSink, ZeroCopyBuffer};

use crate::{hardware_control::live_view::nokhwa::{self, NokhwaCameraInfo}, utils::{ffsend_client::{self, FfSendTransferProgress}, jpeg_encoder}, LogEvent, HardwareInitializationFinishedEvent};

pub fn initialize_log(log_sink: StreamSink<LogEvent>) {
    crate::initialize_log(log_sink);
}

pub fn initialize_hardware(ready_sink: StreamSink<HardwareInitializationFinishedEvent>) {
    crate::initialize_hardware(ready_sink);
}

pub fn nokhwa_get_cameras() -> Vec<NokhwaCameraInfo> {
    return nokhwa::get_cameras();
}

// ////// //
// ffsend //
// ////// //

pub fn ffsend_upload_file(host_url: String, file_path: String, download_filename: Option<String>, max_downloads: Option<u8>, expires_after_seconds: Option<usize>, update_sink: StreamSink<FfSendTransferProgress>) {
    ffsend_client::upload_file(host_url, file_path, download_filename, max_downloads, expires_after_seconds, update_sink)
}

pub fn ffsend_delete_file(file_id: String) {
    ffsend_client::delete_file(file_id)
}

// //// //
// JPEG //
// //// //

pub fn jpeg_encode(width: u16, height: u16, data: Vec<u8>, quality: u8) -> ZeroCopyBuffer<Vec<u8>> {
    jpeg_encoder::encode_rgba(width, height, data, quality)
}
