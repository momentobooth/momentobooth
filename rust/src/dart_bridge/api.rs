use std::{sync::{Mutex, atomic::{AtomicUsize, Ordering, AtomicBool}}, time::Instant};

use dashmap::DashMap;
use ::nokhwa::CallbackCamera;
use flutter_rust_bridge::{StreamSink, ZeroCopyBuffer};
use turborand::rng::Rng;

use crate::{hardware_control::live_view::{nokhwa::{self, NokhwaCameraInfo}, white_noise::{self, WhiteNoiseGeneratorHandle}}, utils::{ffsend_client::{self, FfSendTransferProgress}, jpeg, image_processing::{self, ImageOperation}, flutter_texture::FlutterTexture}, LogEvent, HardwareInitializationFinishedEvent, log_debug};

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

lazy_static::lazy_static! {
    pub static ref NOKHWA_HANDLES: DashMap<usize, NokhwaCameraHandle> = DashMap::<usize, NokhwaCameraHandle>::new();
}

static NOKHWA_HANDLE_COUNT: AtomicUsize = AtomicUsize::new(1);

pub fn nokhwa_open_camera(friendly_name: String, operations: Vec<ImageOperation>, texture_ptr: usize) -> usize {
    let renderer = FlutterTexture::new(texture_ptr, 0, 0);
    let renderer_mutex = Mutex::new(renderer);

    let handle_id = NOKHWA_HANDLE_COUNT.fetch_add(1, Ordering::SeqCst);
    let camera = nokhwa::open_camera(friendly_name, move |raw_frame| {
        let mut handle = NOKHWA_HANDLES.get_mut(&handle_id).expect("Invalid nokhwa handle ID");
        match raw_frame {
            Some(raw_frame) => {
                let processed_frame = image_processing::execute_operations(raw_frame, &operations);
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
        handle.last_frame_timestamp = Some(Instant::now());
    });

    // Store handle
    NOKHWA_HANDLES.insert(handle_id, NokhwaCameraHandle::new(camera));

    handle_id
}

pub fn nokhwa_get_camera_status(handle_id: usize) -> CameraState {
    let handle = NOKHWA_HANDLES.get(&handle_id).expect("Invalid nokhwa handle ID");
    
    CameraState {
        is_streaming: true,
        valid_frame_count: handle.valid_frame_count.load(Ordering::SeqCst),
        error_frame_count: handle.error_frame_count.load(Ordering::SeqCst),
        last_frame_was_valid: handle.last_frame_was_valid.load(Ordering::SeqCst),
    }
}

pub fn nokhwa_get_last_frame(handle_id: usize) -> Option<RawImage> {
    let handle = NOKHWA_HANDLES.get(&handle_id).expect("Invalid nokhwa handle ID");
    handle.last_valid_frame.clone()
}

pub fn nokhwa_close_camera(handle_id: usize) {
    let handle = NOKHWA_HANDLES.remove(&handle_id).expect("Invalid nokhwa handle ID");
    nokhwa::close_camera(handle.1.camera)
}

// ///// //
// Noise //
// ///// //
 
lazy_static::lazy_static! {
    pub static ref NOISE_HANDLES: DashMap<usize, WhiteNoiseGeneratorHandle> = DashMap::<usize, WhiteNoiseGeneratorHandle>::new();
}

static NOISE_HANDLE_COUNT: AtomicUsize = AtomicUsize::new(1);

const NOISE_DEFAULT_WIDTH: usize = 1280;
const NOISE_DEFAULT_HEIGHT: usize = 720;

pub fn noise_open(texture_ptr: usize) -> usize {
    // Initialize noise and push noise frames to Flutter texture
    let renderer = FlutterTexture::new(texture_ptr, NOISE_DEFAULT_WIDTH, NOISE_DEFAULT_HEIGHT);
    let join_handle = white_noise::start_and_get_handle(NOISE_DEFAULT_WIDTH, NOISE_DEFAULT_HEIGHT, move |raw_frame| {
        renderer.on_rgba(&raw_frame)
    });

    // Store handle
    let handle_id = NOISE_HANDLE_COUNT.fetch_add(1, Ordering::SeqCst);
    NOISE_HANDLES.insert(handle_id, join_handle);

    handle_id
}

pub fn noise_get_frame() -> RawImage {
    white_noise::generate_frame(&Rng::new(), NOISE_DEFAULT_WIDTH, NOISE_DEFAULT_HEIGHT)
}

pub fn noise_close(handle_id: usize) {
    // Retrieve handle
    let handle = NOISE_HANDLES.remove(&handle_id).expect("Invalid noise handle ID");

    log_debug("Stopping white noise generator with handle ".to_string() + &handle_id.to_string());
    handle.1.stop();
    log_debug("Stopped white noise generator with handle ".to_string() + &handle_id.to_string());
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

#[derive(Clone)]
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

#[derive(Clone)]
pub enum RawImageFormat {
    Rgba,
}

pub struct NokhwaCameraHandle {
    pub status_sink: Option<StreamSink<CameraState>>,
    pub camera: CallbackCamera,
    pub valid_frame_count: AtomicUsize,
    pub error_frame_count: AtomicUsize,
    pub last_frame_was_valid: AtomicBool,
    pub last_valid_frame: Option<RawImage>,
    pub last_frame_timestamp: Option<Instant>,
}

impl NokhwaCameraHandle {
    fn new(camera: CallbackCamera) -> Self {
        Self {
            status_sink: None,
            camera,
            valid_frame_count: AtomicUsize::new(0),
            error_frame_count: AtomicUsize::new(0),
            last_frame_was_valid: AtomicBool::new(false),
            last_valid_frame: None,
            last_frame_timestamp: None,
        }
    }
}

pub struct CameraState {
    pub is_streaming: bool,
    pub valid_frame_count: usize,
    pub error_frame_count: usize,
    pub last_frame_was_valid: bool,
}
