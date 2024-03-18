use std::{sync::{Mutex, atomic::{AtomicUsize, Ordering, AtomicBool}, Arc}, time::Instant};

use chrono::Duration;
use dashmap::DashMap;
pub use ipp::model::PrinterState;
pub use ipp::model::JobState;
use ::nokhwa::CallbackCamera;

use crate::{frb_generated::StreamSink, hardware_control::live_view::nokhwa::{self, NokhwaCameraInfo}, helpers::log_debug, models::{images::RawImage, live_view::CameraState}, utils::{flutter_texture::FlutterTexture, image_processing::{self, ImageOperation}}};

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
        frame_width: handle.last_valid_frame.as_ref().map(|frame| frame.width),
        frame_height: handle.last_valid_frame.as_ref().map(|frame| frame.height),
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
