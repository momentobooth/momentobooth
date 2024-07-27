use std::{sync::{atomic::{AtomicBool, AtomicU32, Ordering}, Arc, LazyLock, Mutex}, time::Instant};

use chrono::Duration;
use dashmap::DashMap;
use nokhwa::{utils::{CameraInfo, RequestedFormat, RequestedFormatType, FrameFormat}, query, native_api_backend, nokhwa_initialize, CallbackCamera, pixel_format::RgbAFormat};

use crate::{frb_generated::StreamSink, helpers::{log_debug, log_error, log_info}, models::{images::RawImage, live_view::CameraState}, utils::{flutter_texture::FlutterTexture, image_processing::{self, ImageOperation}, jpeg}};

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

    // Open camera and configure callback
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
                        buffer.resolution().width() as u32,
                        buffer.resolution().height() as u32,
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

pub fn close_camera(camera: &mut CallbackCamera) {
    camera.set_callback(|_| {}).expect("Cannot set callback to dummy callback");
}

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

// /////// //
// FRB API //
// /////// //

pub fn nokhwa_get_cameras() -> Vec<NokhwaCameraInfo> {
    get_cameras()
}

pub static NOKHWA_HANDLES: LazyLock<DashMap<u32, Arc<Mutex<NokhwaCameraHandle>>>> = LazyLock::new(|| DashMap::<u32, Arc<Mutex<NokhwaCameraHandle>>>::new());

static NOKHWA_HANDLE_COUNT: AtomicU32 = AtomicU32::new(1);

pub fn nokhwa_open_camera(friendly_name: String, operations: Vec<ImageOperation>, texture_ptr: usize
) -> u32 {
    let renderer = FlutterTexture::new(texture_ptr, 0, 0);
    let renderer_mutex = Mutex::new(renderer);

    let handle_id = NOKHWA_HANDLE_COUNT.fetch_add(1, Ordering::SeqCst);
    let camera = open_camera(friendly_name, move |raw_frame| {
        let camera_ref = NOKHWA_HANDLES.get(&handle_id).expect("Invalid nokhwa handle ID");
        let mut handle = camera_ref.lock().expect("Could not lock on handle");
        match raw_frame {
            Some(raw_frame) => {
                let processed_frame = image_processing::execute_operations(&raw_frame, &handle.operations);
                let mut renderer = renderer_mutex.lock().expect("Could not lock on renderer");

                renderer.set_size(processed_frame.width, processed_frame.height);
                renderer.on_rgba(&processed_frame);

                handle.valid_frame_count.fetch_add(1, Ordering::SeqCst);
                handle.last_frame_was_valid.store(true, Ordering::SeqCst);
                handle.last_valid_frame = Some(processed_frame);
            },
            None => {
                handle.error_frame_count.fetch_add(1, Ordering::SeqCst);
                handle.last_frame_was_valid.store(false, Ordering::SeqCst);
            },
        }
        handle.last_received_frame_timestamp = Some(Instant::now());
    });

    // Store handle
    NOKHWA_HANDLES.insert(handle_id, Arc::new(Mutex::new(NokhwaCameraHandle::new(camera, operations))));

    handle_id
}

pub fn nokhwa_set_operations(handle_id: u32, operations: Vec<ImageOperation>) {
    let camera_ref = NOKHWA_HANDLES.get(&handle_id).expect("Invalid nokhwa handle ID");
    let mut handle = camera_ref.lock().expect("Could not lock on handle");

    handle.operations = operations;
}

pub fn nokhwa_get_camera_status(handle_id: u32) -> CameraState {
    let camera_ref = NOKHWA_HANDLES.get(&handle_id).expect("Invalid nokhwa handle ID");
    let handle = camera_ref.lock().expect("Could not lock on handle");

    CameraState {
        is_streaming: true,
        valid_frame_count: handle.valid_frame_count.load(Ordering::SeqCst),
        error_frame_count: handle.error_frame_count.load(Ordering::SeqCst),
        duplicate_frame_count: 0,
        last_frame_was_valid: handle.last_frame_was_valid.load(Ordering::SeqCst),
        time_since_last_received_frame: handle.last_received_frame_timestamp.map(|timestamp| Duration::from_std(timestamp.elapsed()).expect("Could not convert duration")),
        frame_width: handle.last_valid_frame.as_ref().map(|frame| frame.width),
        frame_height: handle.last_valid_frame.as_ref().map(|frame| frame.height),
    }
}

pub fn nokhwa_get_last_frame(handle_id: u32) -> Option<RawImage> {
    let entry = NOKHWA_HANDLES.get(&handle_id).expect("Invalid nokhwa handle ID");
    let handle = entry.lock().expect("Could not lock on handle");
    handle.last_valid_frame.clone()
}

pub fn nokhwa_close_camera(handle_id: u32) {
    let handle = NOKHWA_HANDLES.remove(&handle_id).expect("Invalid nokhwa handle ID");
    close_camera(&mut handle.1.lock().expect("Could not lock on handle").camera);
}


pub struct NokhwaCameraHandle {
    pub status_sink: Option<StreamSink<CameraState>>,
    pub camera: CallbackCamera,
    pub valid_frame_count: AtomicU32,
    pub error_frame_count: AtomicU32,
    pub last_frame_was_valid: AtomicBool,
    pub last_valid_frame: Option<RawImage>,
    pub last_received_frame_timestamp: Option<Instant>,
    pub operations: Vec<ImageOperation>,
}

impl NokhwaCameraHandle {
    fn new(camera: CallbackCamera, operations: Vec<ImageOperation>) -> Self {
        Self {
            status_sink: None,
            camera,
            valid_frame_count: AtomicU32::new(0),
            error_frame_count: AtomicU32::new(0),
            last_frame_was_valid: AtomicBool::new(false),
            last_valid_frame: None,
            last_received_frame_timestamp: None,
            operations: operations,
        }
    }
}

impl Drop for NokhwaCameraHandle {
    fn drop(&mut self) {
        log_debug("Dropping NokhwaCameraHandle".to_string());
    }
}
