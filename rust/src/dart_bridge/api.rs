use ::nokhwa::CallbackCamera;
use flutter_rust_bridge::{StreamSink, ZeroCopyBuffer};

use crate::{hardware_control::live_view::nokhwa::{self, NokhwaCameraInfo}, utils::{ffsend_client::{self, FfSendTransferProgress}, jpeg_encoder, image_processing::{self, ImageOperation, RawImage}}, LogEvent, HardwareInitializationFinishedEvent};

// ////////////// //
// Initialization //
// ////////////// //

pub fn initialize_log(log_sink: StreamSink<LogEvent>) {
    crate::initialize_log(log_sink);
}

pub fn initialize_hardware(ready_sink: StreamSink<HardwareInitializationFinishedEvent>) {
    crate::initialize_hardware(ready_sink);
}

// ////// //
// Webcam //
// ////// //

pub fn nokhwa_get_cameras() -> Vec<NokhwaCameraInfo> {
    nokhwa::get_cameras()
}

pub fn nokhwa_open_camera(friendly_name: String) -> usize {
    let camera = nokhwa::open_camera(friendly_name);
    let camera_box = Box::new(camera);
    Box::into_raw(camera_box) as usize
}

pub fn nokhwa_set_camera_callback(camera_ptr: usize, operations: Vec<ImageOperation>, new_frame_event_sink: StreamSink<RawImage>) {
    unsafe { 
        let mut camera = Box::from_raw(camera_ptr as *mut CallbackCamera);
        nokhwa::set_camera_callback(&mut camera, move |raw_frame| {
            let processed_frame = image_processing::execute_operations(raw_frame, &operations);
            new_frame_event_sink.add(processed_frame);
        });
        Box::into_raw(camera)
    };
}

pub fn nokhwa_close_camera(camera_ptr: usize) {
    unsafe { 
        let camera = Box::from_raw(camera_ptr as *mut CallbackCamera);
        nokhwa::close_camera(*camera)
    }
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

pub fn jpeg_encode(raw_image: RawImage, quality: u8) -> ZeroCopyBuffer<Vec<u8>> {
    jpeg_encoder::encode_rgba(raw_image, quality)
}

// ///////////////////// //
// RGBA image processing //
// ///////////////////// //

pub fn run_image_pipeline(raw_image: RawImage, operations: Vec<ImageOperation>) -> RawImage {
    image_processing::execute_operations(raw_image, &operations)
}
