use flutter_rust_bridge::{StreamSink, ZeroCopyBuffer};
use ::nokhwa::CallbackCamera;

use crate::{hardware_control::live_view::nokhwa::{self, NokhwaCameraInfo}, utils::ffsend_client::{self, FfSendTransferProgress}, LogEvent, HardwareInitializationFinishedEvent};

pub fn initialize_log(log_sink: StreamSink<LogEvent>) {
    crate::initialize_log(log_sink);
}

pub fn initialize_hardware(ready_sink: StreamSink<HardwareInitializationFinishedEvent>) {
    crate::initialize_hardware(ready_sink);
}

pub fn nokhwa_get_cameras() -> Vec<NokhwaCameraInfo> {
    nokhwa::get_cameras()
}

pub fn nokhwa_open_camera(camera_info: NokhwaCameraInfo) -> CameraOpenResult {
    let camera = nokhwa::open_camera(camera_info);
    let format = camera.camera_format().expect("Could not get camera format");
    let camera_box = Box::new(camera);
    CameraOpenResult {
        width: format.width(),
        height: format.height(),
        camera_ptr: Box::into_raw(camera_box) as usize,
    }
}

pub fn set_camera_callback(camera_ptr: usize, new_frame_event_sink: StreamSink<ZeroCopyBuffer<Vec<u8>>>) {
    unsafe { 
        let mut camera = Box::from_raw(camera_ptr as *mut CallbackCamera);
        nokhwa::set_camera_callback(&mut camera, new_frame_event_sink);
        Box::into_raw(camera)
    };
}

pub fn nokhwa_close_camera(camera_ptr: usize) {
    unsafe { 
        let camera = Box::from_raw(camera_ptr as *mut CallbackCamera);
        nokhwa::close_camera(*camera)
    }
}

pub struct CameraOpenResult {
    pub width: u32,
    pub height: u32,
    pub camera_ptr: usize,
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
