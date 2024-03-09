use std::{sync::{Mutex, atomic::{AtomicUsize, Ordering, AtomicBool}, Arc}, time::Instant, vec};

use chrono::Duration;
use dashmap::DashMap;
pub use ipp::model::PrinterState;
use ::nokhwa::CallbackCamera;
use flutter_rust_bridge::{frb, StreamSink, ZeroCopyBuffer};
use turborand::rng::Rng;

use tokio::sync::Mutex as AsyncMutex;
use url::Url;

use crate::{hardware_control::live_view::{gphoto2::{self, GPhoto2Camera, GPhoto2CameraInfo, GPhoto2CameraSpecialHandling, GPhoto2File}, nokhwa::{self, NokhwaCameraInfo}, white_noise::{self, WhiteNoiseGeneratorHandle}}, log_debug, utils::{ffsend_client::{self, FfSendTransferProgress}, flutter_texture::FlutterTexture, image_processing::{self, ImageOperation}, ipp_client::{self, IppPrinterState}, jpeg::{self, MomentoBoothExifTag}}, HardwareInitializationFinishedEvent, LogEvent, TOKIO_RUNTIME};

// ////////////// //
// Initialization //
// ////////////// //

static HARDWARE_INITIALIZED: AtomicBool = AtomicBool::new(false);

pub fn initialize_log(log_sink: StreamSink<LogEvent>) {
    crate::initialize_log(log_sink);
}

pub fn initialize_hardware(ready_sink: StreamSink<HardwareInitializationFinishedEvent>) {
    if !HARDWARE_INITIALIZED.load(Ordering::SeqCst) {
        // Hardware has not been initialized yet
        crate::initialize_hardware(ready_sink);
        HARDWARE_INITIALIZED.store(true, Ordering::SeqCst);
    } else {
        // Hardware has already been initialized (possible due to Hot Reload)
        log_debug("Possible Hot Reload: Closing any open cameras and noise generators".to_string());
        for map_entry in NOKHWA_HANDLES.iter() {
            map_entry.value().lock().expect("Could not lock on handle").camera.set_callback(|_| {}).expect("Stream close error");
        }
        log_debug("Possible Hot Reload: Closed nokhwa".to_string());
        NOKHWA_HANDLES.clear();
        for map_entry in GPHOTO2_HANDLES.iter() {
            TOKIO_RUNTIME.get().expect("Could not get tokio runtime").block_on(async{
                gphoto2::stop_liveview(map_entry.value().lock().expect("Could not lock camera").camera.clone()).await
            }).expect("Could not get result")
        }
        log_debug("Possible Hot Reload: Closed gphoto2".to_string());
        GPHOTO2_HANDLES.clear();
        for map_entry in NOISE_HANDLES.iter() {
            noise_close(*map_entry.key())
        }
        log_debug("Possible Hot Reload: Closed noise".to_string());
    }
}

// ////// //
// Webcam //
// ////// //

pub fn nokhwa_get_cameras() -> Vec<NokhwaCameraInfo> {
    nokhwa::get_cameras()
}

lazy_static::lazy_static! {
    pub static ref NOKHWA_HANDLES: DashMap<usize, Arc<Mutex<NokhwaCameraHandle>>> = DashMap::<usize, Arc<Mutex<NokhwaCameraHandle>>>::new();
}

static NOKHWA_HANDLE_COUNT: AtomicUsize = AtomicUsize::new(1);

pub fn nokhwa_open_camera(friendly_name: String, operations: Vec<ImageOperation>, texture_ptr: usize
) -> usize {
    let renderer = FlutterTexture::new(texture_ptr, 0, 0);
    let renderer_mutex = Mutex::new(renderer);

    let handle_id = NOKHWA_HANDLE_COUNT.fetch_add(1, Ordering::SeqCst);
    let camera = nokhwa::open_camera(friendly_name, move |raw_frame| {
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

pub fn nokhwa_set_operations(handle_id: usize, operations: Vec<ImageOperation>) {
    let camera_ref = NOKHWA_HANDLES.get(&handle_id).expect("Invalid nokhwa handle ID");
    let mut handle = camera_ref.lock().expect("Could not lock on handle");

    handle.operations = operations;
}

pub fn nokhwa_get_camera_status(handle_id: usize) -> CameraState {
    let camera_ref = NOKHWA_HANDLES.get(&handle_id).expect("Invalid nokhwa handle ID");
    let handle = camera_ref.lock().expect("Could not lock on handle");
    
    CameraState {
        is_streaming: true,
        valid_frame_count: handle.valid_frame_count.load(Ordering::SeqCst),
        error_frame_count: handle.error_frame_count.load(Ordering::SeqCst),
        duplicate_frame_count: 0,
        last_frame_was_valid: handle.last_frame_was_valid.load(Ordering::SeqCst),
        time_since_last_received_frame: handle.last_received_frame_timestamp.map(|timestamp| Duration::from_std(timestamp.elapsed()).expect("Could not convert duration")),
        frame_width: Some(NOISE_WIDTH),
        frame_height: Some(NOISE_HEIGHT),
    }
}

pub fn nokhwa_get_last_frame(handle_id: usize) -> Option<RawImage> {
    let entry = NOKHWA_HANDLES.get(&handle_id).expect("Invalid nokhwa handle ID");
    let handle = entry.lock().expect("Could not lock on handle");
    handle.last_valid_frame.clone()
}

pub fn nokhwa_close_camera(handle_id: usize) {
    let handle = NOKHWA_HANDLES.remove(&handle_id).expect("Invalid nokhwa handle ID");
    nokhwa::close_camera(&mut handle.1.lock().expect("Could not lock on handle").camera);
}

// ///// //
// Noise //
// ///// //
 
lazy_static::lazy_static! {
    pub static ref NOISE_HANDLES: DashMap<usize, WhiteNoiseGeneratorHandle> = DashMap::<usize, WhiteNoiseGeneratorHandle>::new();
}

static NOISE_HANDLE_COUNT: AtomicUsize = AtomicUsize::new(1);

const NOISE_WIDTH: usize = 1280;
const NOISE_HEIGHT: usize = 720;

pub fn noise_open(texture_ptr: usize) -> usize {
    // Initialize noise and push noise frames to Flutter texture
    let renderer_main = FlutterTexture::new(texture_ptr, NOISE_WIDTH, NOISE_HEIGHT);
    let join_handle = white_noise::start_and_get_handle(NOISE_WIDTH, NOISE_HEIGHT, move |raw_frame| {
        renderer_main.on_rgba(&raw_frame);
    });

    // Store handle
    let handle_id = NOISE_HANDLE_COUNT.fetch_add(1, Ordering::SeqCst);
    NOISE_HANDLES.insert(handle_id, join_handle);

    handle_id
}

pub fn noise_get_frame() -> RawImage {
    white_noise::generate_frame(&Rng::new(), NOISE_WIDTH, NOISE_HEIGHT)
}

pub fn noise_close(handle_id: usize) {
    // Retrieve handle
    let handle = NOISE_HANDLES.remove(&handle_id).expect("Invalid noise handle ID");

    log_debug("Stopping white noise generator with handle ".to_string() + &handle_id.to_string());
    handle.1.stop();
    log_debug("Stopped white noise generator with handle ".to_string() + &handle_id.to_string());
}

// //////////// //
// Static image //
// //////////// //

pub fn static_image_write_to_texture(raw_image: RawImage, texture_ptr: usize) {
    let renderer_main = FlutterTexture::new(texture_ptr, raw_image.width, raw_image.height);
    renderer_main.on_rgba(&raw_image);
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

pub fn jpeg_encode(raw_image: RawImage, quality: u8, exif_tags: Vec<MomentoBoothExifTag>, operations_before_encoding: Vec<ImageOperation>) -> ZeroCopyBuffer<Vec<u8>> {
    let processed_image = image_processing::execute_operations(&raw_image, &operations_before_encoding);
    jpeg::encode_raw_to_jpeg(processed_image, quality, exif_tags)
}

pub fn jpeg_decode(jpeg_data: Vec<u8>, operations_after_decoding: Vec<ImageOperation>) -> RawImage {
    let image = jpeg::decode_jpeg_to_rgba(&jpeg_data);
    image_processing::execute_operations(&image, &operations_after_decoding)
}

// ///////////////////// //
// RGBA image processing //
// ///////////////////// //

pub fn run_image_pipeline(raw_image: RawImage, operations: Vec<ImageOperation>) -> RawImage {
    image_processing::execute_operations(&raw_image, &operations)
}

// /////// //
// gPhoto2 //
// /////// //

lazy_static::lazy_static! {
    pub static ref GPHOTO2_HANDLES: DashMap<usize, Arc<Mutex<GPhoto2CameraHandle>>> = DashMap::<usize, Arc<Mutex<GPhoto2CameraHandle>>>::new();
}

static GPHOTO2_HANDLE_COUNT: AtomicUsize = AtomicUsize::new(1);

pub fn gphoto2_get_cameras() -> Vec<GPhoto2CameraInfo> {
    gphoto2::get_cameras().expect("Could not enumerate cameras")
}

pub fn gphoto2_open_camera(model: String, port: String, special_handling: GPhoto2CameraSpecialHandling) -> usize {
    let camera = TOKIO_RUNTIME.get().expect("Could not get tokio runtime").block_on(async {
        gphoto2::open_camera(model, port, special_handling).await
    }).expect("Could not open camera");

    // Store handle
    let handle_id = GPHOTO2_HANDLE_COUNT.fetch_add(1, Ordering::SeqCst);
    GPHOTO2_HANDLES.insert(handle_id, Arc::new(Mutex::new(GPhoto2CameraHandle::new(camera, vec!()))));

    handle_id
}

pub fn gphoto2_close_camera(handle_id: usize) {
    gphoto2_stop_liveview(handle_id);
    GPHOTO2_HANDLES.remove(&handle_id).expect("Invalid nokhwa handle ID");
}

pub fn gphoto2_start_liveview(handle_id: usize, operations: Vec<ImageOperation>, texture_ptr: usize) {
    let renderer = FlutterTexture::new(texture_ptr, 0, 0);
    let renderer_mutex = Mutex::new(renderer);

    let camera_ref = GPHOTO2_HANDLES.get(&handle_id).expect("Invalid gPhoto2 handle ID");
    let mut camera_handle = camera_ref.lock().expect("Could not lock camera");
    camera_handle.operations = operations;

    let camera = camera_handle.camera.clone();

    TOKIO_RUNTIME.get().expect("Could not get tokio runtime").block_on(async {
        gphoto2::start_liveview(camera, move |raw_frame| {
            let camera_ref = GPHOTO2_HANDLES.get(&handle_id).expect("Invalid gPhoto2 handle ID");
            let camera_arc = camera_ref.clone();
            let mut camera = camera_arc.lock().expect("Could not lock camera");

            match raw_frame {
                Ok(raw_frame) => {
                    let processed_frame = image_processing::execute_operations(&raw_frame, &camera.operations);
                    let mut renderer = renderer_mutex.lock().expect("Could not lock on renderer");

                    renderer.set_size(processed_frame.width, processed_frame.height);
                    renderer.on_rgba(&processed_frame);
                    
                    camera.valid_frame_count.fetch_add(1, Ordering::SeqCst);
                    camera.last_frame_was_valid.store(true, Ordering::SeqCst);
                    camera.last_valid_frame = Some(processed_frame);
                },
                Err(_) => {
                    camera.error_frame_count.fetch_add(1, Ordering::SeqCst);
                    camera.last_frame_was_valid.store(false, Ordering::SeqCst);
                },
            }
        }, move || {
            let camera_ref = GPHOTO2_HANDLES.get(&handle_id).expect("Invalid gPhoto2 handle ID");
            let camera_arc = camera_ref.clone();
            let camera = camera_arc.lock().expect("Could not lock camera");
            camera.duplicate_frame_count.fetch_add(1, Ordering::SeqCst);
        }).await
    }).expect("Could not start live view")
}

pub fn gphoto2_set_operations(handle_id: usize, operations: Vec<ImageOperation>) {
    let camera_ref = GPHOTO2_HANDLES.get(&handle_id).expect("Invalid gPhoto2 handle ID");
    let mut camera_handle = camera_ref.lock().expect("Could not lock camera");
    camera_handle.operations = operations;
}

pub fn gphoto2_stop_liveview(handle_id: usize) {
    let camera_ref = GPHOTO2_HANDLES.get(&handle_id).expect("Invalid gPhoto2 handle ID");
    let camera = camera_ref.clone().lock().expect("Could not lock camera").camera.clone();

    TOKIO_RUNTIME.get().expect("Could not get tokio runtime").block_on(async{
        gphoto2::stop_liveview(camera).await
    }).expect("Could not get result")
}

pub fn gphoto2_auto_focus(handle_id: usize) {
    let camera_ref: dashmap::mapref::one::Ref<'_, usize, Arc<Mutex<GPhoto2CameraHandle>>> = GPHOTO2_HANDLES.get(&handle_id).expect("Invalid gPhoto2 handle ID");
    let camera = camera_ref.clone().lock().expect("Could not lock camera").camera.clone();

    TOKIO_RUNTIME.get().expect("Could not get tokio runtime").block_on(async{
        gphoto2::auto_focus(camera).await        
    }).expect("Could not get result")
}

pub fn gphoto2_clear_events(handle_id: usize, download_extra_files: bool) {
    let camera_ref = GPHOTO2_HANDLES.get(&handle_id).expect("Invalid gPhoto2 handle ID");
    let camera = camera_ref.clone().lock().expect("Could not lock camera").camera.clone();

    TOKIO_RUNTIME.get().expect("Could not get tokio runtime").block_on(async{
        gphoto2::clear_events(camera, download_extra_files).await        
    }).expect("Could not get result")
}

pub fn gphoto2_capture_photo(handle_id: usize, capture_target_value: String) -> GPhoto2File {
    let camera_ref = GPHOTO2_HANDLES.get(&handle_id).expect("Invalid gPhoto2 handle ID");
    let camera = camera_ref.clone().lock().expect("Could not lock camera").camera.clone();

    TOKIO_RUNTIME.get().expect("Could not get tokio runtime").block_on(async{
        gphoto2::capture_photo(camera, capture_target_value).await        
    }).expect("Could not get result")
}

pub fn gphoto2_get_camera_status(handle_id: usize) -> CameraState {
    let camera_ref = GPHOTO2_HANDLES.get(&handle_id).expect("Invalid gPhoto2 handle ID");
    let camera_arc = camera_ref.clone();
    let camera = camera_arc.lock().expect("Could not lock camera");
    
    CameraState {
        is_streaming: true,
        valid_frame_count: camera.valid_frame_count.load(Ordering::SeqCst),
        error_frame_count: camera.error_frame_count.load(Ordering::SeqCst),
        duplicate_frame_count: camera.duplicate_frame_count.load(Ordering::SeqCst),
        last_frame_was_valid: camera.last_frame_was_valid.load(Ordering::SeqCst),
        time_since_last_received_frame: camera.last_received_frame_timestamp.map(|timestamp| Duration::from_std(timestamp.elapsed()).expect("Could not convert duration")),
        frame_width: camera.last_valid_frame.clone().map(|frame| frame.width),
        frame_height: camera.last_valid_frame.clone().map(|frame| frame.height),
    }
}

pub fn gphoto2_get_last_frame(handle_id: usize) -> Option<RawImage> {
    let camera_ref = GPHOTO2_HANDLES.get(&handle_id).expect("Invalid gPhoto2 handle ID");
    let camera_arc = camera_ref.clone();
    let camera = camera_arc.lock().expect("Could not lock camera");
    camera.last_valid_frame.clone()
}

pub fn gphoto2_set_extra_file_callback(handle_id: usize, image_sink: StreamSink<GPhoto2File>) {
    let camera_ref = GPHOTO2_HANDLES.get(&handle_id).expect("Invalid gPhoto2 handle ID");
    let camera = camera_ref.clone().lock().expect("Could not lock camera").camera.clone();

    TOKIO_RUNTIME.get().expect("Could not get tokio runtime").block_on(async{
        gphoto2::set_extra_file_callback(camera, move |data| {
            image_sink.add(data);
        }).await;
    })
}

// ////////// //
// IPP (CUPS) //
// ////////// //

fn cups_build_url(printer_id: String) -> String {
    let base = Url::parse("http://localhost:631/").unwrap();
    base.join("printers").unwrap().join(&printer_id).unwrap().to_string()
}

pub fn cups_get_printer_state(printer_id: String) -> IppPrinterState {
    let uri = cups_build_url(printer_id);
    ipp_client::get_printer_state(uri)
}

pub fn cups_resume_printer(printer_id: String) {
    let uri = cups_build_url(printer_id);
    ipp_client::resume_printer(uri);
}

// /////// //
// Structs //
// /////// //

#[frb(mirror(PrinterState))]
pub enum _PrinterState {
    Idle = 3,
    Processing = 4,
    Stopped = 5,
}

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
    pub last_received_frame_timestamp: Option<Instant>,
    pub operations: Vec<ImageOperation>,
}

impl NokhwaCameraHandle {
    fn new(camera: CallbackCamera, operations: Vec<ImageOperation>) -> Self {
        Self {
            status_sink: None,
            camera,
            valid_frame_count: AtomicUsize::new(0),
            error_frame_count: AtomicUsize::new(0),
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

pub struct GPhoto2CameraHandle {
    pub status_sink: Option<StreamSink<CameraState>>,
    pub camera: Arc<AsyncMutex<GPhoto2Camera>>,
    pub valid_frame_count: AtomicUsize,
    pub error_frame_count: AtomicUsize,
    pub duplicate_frame_count: AtomicUsize,
    pub last_frame_was_valid: AtomicBool,
    pub last_valid_frame: Option<RawImage>,
    pub last_received_frame_timestamp: Option<Instant>,
    pub operations: Vec<ImageOperation>,
}

impl GPhoto2CameraHandle {
    fn new(camera: GPhoto2Camera, operations: Vec<ImageOperation>) -> Self {
        Self {
            status_sink: None,
            camera: Arc::new(AsyncMutex::new(camera)),
            valid_frame_count: AtomicUsize::new(0),
            error_frame_count: AtomicUsize::new(0),
            duplicate_frame_count: AtomicUsize::new(0),
            last_frame_was_valid: AtomicBool::new(false),
            last_valid_frame: None,
            last_received_frame_timestamp: None,
            operations: operations,
        }
    }
}

impl Drop for GPhoto2CameraHandle {
    fn drop(&mut self) {
        log_debug("Dropping GPhoto2CameraHandle".to_string());
    }
}

pub struct CameraState {
    pub is_streaming: bool,
    pub valid_frame_count: usize,
    pub error_frame_count: usize,
    pub duplicate_frame_count: usize,
    pub last_frame_was_valid: bool,
    pub time_since_last_received_frame: Option<Duration>,
    pub frame_width: Option<usize>,
    pub frame_height: Option<usize>,
}
