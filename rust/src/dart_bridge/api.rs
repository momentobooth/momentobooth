use std::sync::Mutex;

use ::nokhwa::CallbackCamera;
use flutter_rust_bridge::{StreamSink, ZeroCopyBuffer};

use crate::{hardware_control::live_view::nokhwa::{self, NokhwaCameraInfo}, utils::{ffsend_client::{self, FfSendTransferProgress}, jpeg, image_processing::{self, ImageOperation}, flutter_texture::FlutterTexture}, LogEvent, HardwareInitializationFinishedEvent};

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

pub fn nokhwa_open_camera(friendly_name: String, operations: Vec<ImageOperation>, texture_ptr: usize) -> usize {
    let renderer = FlutterTexture::new(texture_ptr, 0, 0);
    let renderer_mutex = Mutex::new(renderer);
    let camera = nokhwa::open_camera(friendly_name, move |raw_frame| {
        match raw_frame {
            Some(raw_frame) => {
                let processed_frame = image_processing::execute_operations(raw_frame, &operations);
                let mut renderer = renderer_mutex.lock().expect("Could not lock on renderer");
                renderer.set_size(processed_frame.width, processed_frame.height);
                renderer.on_rgba(processed_frame)
            },
            None => {
                // TODO: Handle? Maybe send a green frame?
            },
        }
    });
    let camera_box = Box::new(camera);
    Box::into_raw(camera_box) as usize
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

pub fn jpeg_encode(raw_image: RawImage, quality: u8, operations_before_encoding: Vec<ImageOperation>) -> ZeroCopyBuffer<Vec<u8>> {
    let processed_image = image_processing::execute_operations(raw_image, &operations_before_encoding);
    jpeg::encode_raw_to_jpeg(processed_image, quality)
}

pub fn jpeg_decode(jpeg_data: Vec<u8>, operations_after_decoding: Vec<ImageOperation>) -> RawImage {
    let image = jpeg::decode_jpeg_to_rgba(&jpeg_data);
    image_processing::execute_operations(image, &operations_after_decoding)
}

// ///////////////////// //
// RGBA image processing //
// ///////////////////// //

pub fn run_image_pipeline(raw_image: RawImage, operations: Vec<ImageOperation>) -> RawImage {
    image_processing::execute_operations(raw_image, &operations)
}

// /////// //
// Structs //
// /////// //

pub struct RawImage {
    pub format: RawImageFormat,
    pub data: Vec<u8>,
    pub width: usize,
    pub height: usize,
}

impl RawImage {
    pub(crate) fn new_from_rgba_data(data: Vec<u8>, width: usize, height: usize) -> RawImage {
        Self {
            format: RawImageFormat::Rgba,
            data,
            width,
            height,
        }
    }
}

pub enum RawImageFormat {
    Rgba,
}
