use derive_more::{From, Into};
use nokhwa::{utils::{CameraInfo, RequestedFormat, RequestedFormatType}, query, native_api_backend, nokhwa_initialize, CallbackCamera, pixel_format::RgbAFormat};

use crate::{log, utils::image_processing::RawImage};

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

pub fn open_camera(friendly_name: String) -> CallbackCamera {
    let format = RequestedFormat::new::<RgbAFormat>(RequestedFormatType::AbsoluteHighestResolution);
    
    // Look up device name
    let backend = native_api_backend().unwrap();
    let devices = query(backend).unwrap();
    let camera_info = devices.into_iter().find(|device| device.human_name() == friendly_name).expect("Could not find camera");

    let mut camera = CallbackCamera::new(camera_info.index().clone(), format, |_| {}).expect("Could not create CallbackCamera");

    camera.open_stream().expect("Could not open camera stream");
    log("Opened camera successfully; ".to_string() + "Camera format: " + &camera.camera_format().expect("Could not get camera format").to_string());

    camera
}

pub fn set_camera_callback<F>(camera: &mut CallbackCamera, frame_callback: F) where F: Fn(RawImage) + Send + Sync + 'static {
    camera.set_callback(move |buffer| {
        let image = buffer.decode_image::<RgbAFormat>().expect("Could not decode image to RGBA");
        let frame = RawImage {
            width: buffer.resolution().width() as usize,
            height: buffer.resolution().height() as usize,
            raw_rgba_data: image.to_vec(),
        };
        frame_callback(frame);
    }).expect("Failed setting the callback");
}

pub fn close_camera(mut camera: CallbackCamera) {
    camera.set_callback(|_| {}).expect("Could not set callback")
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

impl NokhwaCameraInfo {
    pub fn from_camera_info(camera_info: &CameraInfo) -> Self {
        Self { id: camera_info.index().as_index().expect("Could not get camera index"), friendly_name: camera_info.human_name() }
    }
}
