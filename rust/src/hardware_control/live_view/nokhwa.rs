use std::{sync::Mutex};

use atom_table::AtomTable;
use derive_more::{From, Into};
use flutter_rust_bridge::{StreamSink, ZeroCopyBuffer};
use nokhwa::{utils::{CameraInfo, RequestedFormat, RequestedFormatType}, query, native_api_backend, nokhwa_initialize, CallbackCamera, pixel_format::{RgbFormat, RgbAFormat}};
use nokhwa::utils::CameraIndex::Index;
use once_cell::sync::Lazy;

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

pub fn open_camera(camera_info: NokhwaCameraInfo, new_image_event_sink: StreamSink<ZeroCopyBuffer<Vec<u8>>>) {
    let format = RequestedFormat::<'static>::new::<RgbFormat>(RequestedFormatType::AbsoluteHighestResolution);

    let mut camera = CallbackCamera::new(Index(camera_info.id), format, move |buffer| {
        let image = buffer.decode_image::<RgbAFormat>().unwrap();
        let event_buffer = ZeroCopyBuffer(image.to_vec());
        new_image_event_sink.add(event_buffer);
    }).unwrap();

    let camera_open_result = camera.open_stream();
    if camera_open_result.is_err() {
        let err = camera_open_result.unwrap_err();
        log("Camera open error: ".to_string() + &err.to_string());
    } else {
        log("Opened camera successfully; ".to_string() + "Camera format: " + &camera.camera_format().unwrap().to_string());
    }
}

pub fn close_camera() {

}

// //////////////////////// //
// Nokhwa handle management //
// //////////////////////// //

static OPEN_CAMERAS: Lazy<Mutex<AtomTable<String, Id>>> = Lazy::new(|| Mutex::new(AtomTable::new()));

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
        Self { id: camera_info.index().as_index().unwrap(), friendly_name: camera_info.human_name() }
    }
}
