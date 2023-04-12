use derive_more::{From, Into};
use flutter_rust_bridge::{StreamSink, ZeroCopyBuffer};
use nokhwa::{utils::{CameraInfo, RequestedFormat, RequestedFormatType}, query, native_api_backend, nokhwa_initialize, CallbackCamera, pixel_format::RgbAFormat};
use nokhwa::utils::CameraIndex::Index;

use crate::log;

pub fn initialize<F>(on_complete: F) where F: Fn(bool) + std::marker::Send + std::marker::Sync + 'static {
    if cfg!(target_os = "macos") {
        nokhwa_initialize(on_complete);
    } else {
        on_complete(true);
    }
}

pub fn get_cameras() -> Vec<NokhwaCameraInfo> {
    let backend = native_api_backend().unwrap();
    let devices = query(backend).unwrap();

    let device_names: Vec<NokhwaCameraInfo> = devices.iter().map(NokhwaCameraInfo::from_camera_info).collect();
    device_names
}

pub fn open_camera(camera_info: NokhwaCameraInfo) -> CameraOpenResult {
    let format = RequestedFormat::new::<RgbAFormat>(RequestedFormatType::AbsoluteHighestResolution);

    let mut camera = CallbackCamera::new(Index(camera_info.id), format, move |_| {}).expect("Could not create CallbackCamera");

    camera.open_stream().expect("Could not open camera stream");
    log("Opened camera successfully; ".to_string() + "Camera format: " + &camera.camera_format().expect("Could not get camera format").to_string());

    // Return camera handle
    let camera = Box::new(camera);
    let format = camera.camera_format().expect("Could not get camera format");
    CameraOpenResult {
        width: format.width(),
        height: format.height(),
        camera_ptr: Box::into_raw(camera) as usize,
    }
}

pub fn set_camera_callback(camera_ptr: usize, new_frame_event_sink: StreamSink<ZeroCopyBuffer<Vec<u8>>>) {
    unsafe { 
        let mut camera: Box<CallbackCamera> = Box::from_raw(camera_ptr as *mut CallbackCamera);
        camera.set_callback(move |buffer| {
            let image = buffer.decode_image::<RgbAFormat>().expect("Could not decode image to RGBA");
            let event_buffer = ZeroCopyBuffer(image.to_vec());
            new_frame_event_sink.add(event_buffer);
        }).expect("Failed setting the callback");
        Box::into_raw(camera)
    };
}

pub fn close_camera(camera_ptr: usize) {
    unsafe { 
        let mut camera: Box<CallbackCamera> = Box::from_raw(camera_ptr as *mut CallbackCamera);
        camera.set_callback(|_| {}).expect("Could not set callback")
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, From, Into)]
struct Id(usize);

// /////// //
// Structs //
// /////// //

pub struct NokhwaCameraInfo {
    pub id: u32,
    pub friendly_name: String,
}

pub struct CameraOpenResult {
    pub width: u32,
    pub height: u32,
    pub camera_ptr: usize,
}

impl NokhwaCameraInfo {
    pub fn from_camera_info(camera_info: &CameraInfo) -> Self {
        Self { id: camera_info.index().as_index().expect("Could not get camera index"), friendly_name: camera_info.human_name() }
    }
}
