use derive_more::{From, Into};
use nokhwa::{utils::{CameraInfo, RequestedFormat, RequestedFormatType, FrameFormat}, query, native_api_backend, nokhwa_initialize, CallbackCamera, pixel_format::RgbAFormat};

use crate::{dart_bridge::api::RawImage, log_debug, log_info, log_error, utils::jpeg};

pub fn initialize<F>(on_complete: F) where F: Fn(bool) + std::marker::Send + std::marker::Sync + 'static {
    if cfg!(target_os = "macos") {
        nokhwa_initialize(on_complete);
    } else {
        on_complete(true);
    }
}

pub fn get_cameras() -> Vec<NokhwaCameraInfo> {
    let backend = native_api_backend().expect("Could not get backend");
    let devices = query(backend).expect("Could not query backend");

    let device_names: Vec<NokhwaCameraInfo> = devices.iter().map(NokhwaCameraInfo::from_camera_info).collect();
    device_names
}

pub fn open_camera<F>(friendly_name: String, frame_callback: F) -> CallbackCamera where F: Fn(Option<RawImage>) + Send + Sync + 'static {
    log_debug("nokhwa::open_camera() opening '".to_string() + &friendly_name + "'");
    let format = RequestedFormat::new::<RgbAFormat>(RequestedFormatType::AbsoluteHighestResolution);
    
    // Look up device name
    let backend = native_api_backend().expect("Could not get backend");
    let devices = query(backend).expect("Could not query backend");
    let camera_info = devices.into_iter().find(|device| device.human_name() == friendly_name).expect("Could not find camera");

    // Open camera and configure callback7
    let mut camera = CallbackCamera::new(camera_info.index().clone(), format, move |buffer| {
        if buffer.source_frame_format() == FrameFormat::MJPEG {
            // MJPEG: Use our own implementation which is faster
            let raw_image = jpeg::decode_jpeg_to_rgba(buffer.buffer()); // TODO: Handle errors (this should return Option<RawImage>)
            frame_callback(Some(raw_image));
        } else {
            // YUV, Gray, etc.
            let raw_rgba_image = buffer.decode_image::<RgbAFormat>();
            let raw_image_option = match raw_rgba_image {
                Ok(image_buffer) => {
                    Some(RawImage::new_from_rgba_data(
                        image_buffer.into_vec(),
                        buffer.resolution().width() as usize,
                        buffer.resolution().height() as usize,
                    ))
                },
                Err(error) => {
                    log_error("Image decoding error: ".to_string() + &error.to_string());
                    None
                },
            };
            frame_callback(raw_image_option)
        }
    }).expect("Could not create CallbackCamera");

    camera.open_stream().expect("Could not open camera stream");
    let camera_format_str = &camera.camera_format().expect("Could not get camera format").to_string();
    log_info("nokhwa::open_camera() opened '".to_string() + &friendly_name + "' (" + camera_format_str + ")");

    camera
}

pub fn close_camera(camera: CallbackCamera) {
    let camera_name = camera.info().human_name();
    drop(camera);
    log_info("nokhwa::close_camera() dropped '".to_string() + &camera_name + "'");
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
