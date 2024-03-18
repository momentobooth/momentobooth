use std::{sync::{Mutex, atomic::{AtomicUsize, Ordering, AtomicBool}, Arc}, time::Instant, vec};

use chrono::Duration;
use dashmap::DashMap;
pub use ipp::model::PrinterState;
pub use ipp::model::JobState;
use tokio::sync::Mutex as AsyncMutex;

use crate::{frb_generated::StreamSink, hardware_control::live_view::gphoto2::{self, GPhoto2Camera, GPhoto2CameraInfo, GPhoto2CameraSpecialHandling, GPhoto2File}, helpers::{log_debug, TOKIO_RUNTIME}, models::{images::RawImage, live_view::CameraState}, utils::{flutter_texture::FlutterTexture, image_processing::{self, ImageOperation}}};

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

    crate::helpers::TOKIO_RUNTIME.get().expect("Could not get tokio runtime").block_on(async{
        gphoto2::set_extra_file_callback(camera, move |data| {
            image_sink.add(data);
        }).await;
    })
}

// /////// //
// Structs //
// /////// //

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
