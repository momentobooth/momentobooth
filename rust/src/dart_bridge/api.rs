use flutter_rust_bridge::StreamSink;

use crate::{hardware_control::live_view::nokhwa::{self, NokhwaCameraInfo}, utils::ffsend_client::{self, FfSendTransferProgress}, LogEvent, HardwareInitializationFinishedEvent};

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

pub fn ffsend_upload_file(host_url: String, file_path: String, download_filename: Option<String>, update_sink: StreamSink<FfSendTransferProgress>) {
    ffsend_client::upload_file(host_url, file_path, download_filename, update_sink)
}
