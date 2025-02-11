use std::{cell::Cell, env, hash::{Hash, Hasher}, sync::{atomic::{AtomicBool, AtomicU32, Ordering}, Arc, OnceLock}, time::Instant};

use ahash::AHasher;

use ::gphoto2::{camera::CameraEvent, list::CameraDescriptor, widget::{RadioWidget, TextWidget, ToggleWidget}, Camera, Context, Error};
use parking_lot::Mutex;
use tokio::{sync::Mutex as AsyncMutex, time::sleep};
use tokio::task::JoinHandle as AsyncJoinHandle;
use log::{warn, debug, info};

use crate::{models::images::RawImage, utils::jpeg};
use crate::TOKIO_RUNTIME;
use crate::{frb_generated::StreamSink, hardware_control::live_view::gphoto2::{self}, models::live_view::CameraState, utils::{flutter_texture::FlutterTexture, image_processing::{self, ImageOperation}}};

use chrono::Duration;
use dashmap::DashMap;
use flutter_rust_bridge::frb;
use std::sync::LazyLock;

static CONTEXT: OnceLock<Context> = OnceLock::new();

fn get_context() -> Result<&'static Context> {
  CONTEXT.get().ok_or(Gphoto2Error::ContextNotInitialized)
}

pub fn initialize(iolibs_path: String, camlibs_path: String) -> Result<()> {
  if CONTEXT.get().is_some() {
    // Already initialized
    return Ok(())
  }

  // Initialize CAMLIBS and IOLIBS path
  if !iolibs_path.is_empty() && !camlibs_path.is_empty() {
      let mut full_iolibs_path = env::current_exe().unwrap();
      full_iolibs_path.pop();
      full_iolibs_path.push(iolibs_path);
      let full_iolibs_path_str = full_iolibs_path.canonicalize().unwrap().to_str().unwrap().trim_start_matches(r"\\?\").to_owned();
      set_environment_variable("IOLIBS", &full_iolibs_path_str);

      let mut full_camlibs_path = env::current_exe().unwrap();
      full_camlibs_path.pop();
      full_camlibs_path.push(camlibs_path);
      let full_camlibs_path_str = full_camlibs_path.canonicalize().unwrap().to_str().unwrap().trim_start_matches(r"\\?\").to_owned();
      set_environment_variable("CAMLIBS", &full_camlibs_path_str);

      debug!("initialize_hardware(): iolibs: {}, camlibs: {}", full_iolibs_path_str, full_camlibs_path_str);
  } else {
      debug!("{}", "initialize_hardware(): no override of iolibs or camlibs path");
  }

  let context = Context::new()?;
  CONTEXT.get_or_init(|| context);

  Ok(())
}

pub fn get_cameras() -> Result<Vec<GPhoto2CameraInfo>> {
  let mut cameras: Vec<GPhoto2CameraInfo> = Vec::new();
  for CameraDescriptor { model, port } in get_context()?.list_cameras().wait().expect("Could not list cameras") {
    cameras.push(GPhoto2CameraInfo::from_camera_descriptor(CameraDescriptor { model, port }));
  }

  Ok(cameras)
}

pub async fn open_camera(model: String, _: String, special_handling: GPhoto2CameraSpecialHandling) -> Result<GPhoto2Camera> {
  let camera_descriptor = get_context()?.list_cameras().await.expect("Could not enumerate cameras").into_iter().find(|camera| camera.model == model).expect("Could not find camera");
  let camera = get_context()?.get_camera(&camera_descriptor).await?;

  Ok(GPhoto2Camera {
    camera,
    special_handling,
    thread_join_handle: Cell::new(None),
    thread_should_stop: AtomicBool::new(false),
    extra_file_callback: None,
  })
}

pub async fn start_liveview<F, D>(camera_ref: Arc<AsyncMutex<GPhoto2Camera>>, frame_callback: F, duplicate_frame_callback: D) -> Result<()> where F: Fn(Result<RawImage>) + Send + Sync + 'static, D: Fn() + Send + Sync + 'static {
  let mut camera = camera_ref.lock().await;

  // TODO: check if join handle not already set

  match camera.special_handling {
    GPhoto2CameraSpecialHandling::NikonDSLR => {
      let opcode = camera.camera.config_key::<TextWidget>("opcode").await?;
      opcode.set_value("0x9201")?;
      camera.camera.set_config(&opcode).await?;
    },
    _ => {},
  }

  let camera_ref = camera_ref.clone();
  let join_handle = tokio::spawn(async move {
    let context = get_context().expect("TODO: handle this");

    let last_hash = Cell::new(0);

    loop {
      let camera = camera_ref.lock().await;
      let mut preview = camera.camera.capture_preview().await;
      if preview.is_err() {
        warn!("{}", "Capture preview error, waiting 2s before trying again...");
        sleep(tokio::time::Duration::from_millis(2000)).await;
        preview = camera.camera.capture_preview().await;
      }
      drop(camera);

      let data = preview.unwrap().get_data(&context).await.expect("Could not get preview data");
      let hash = hash_box(&data);
      if hash == last_hash.get() {
        // Frame is the same as the last one, skip
        duplicate_frame_callback();
        sleep(Duration::milliseconds(8).to_std().unwrap()).await;
        continue;
      }

      let raw_image = jpeg::decode_jpeg_to_rgba(&data); // TODO: Handle errors (this should return Option<RawImage>)
      frame_callback(Ok(raw_image));

      last_hash.set(hash);
    }
  });

  camera.thread_join_handle = Cell::new(Some(join_handle));

  Ok(())
}

fn hash_box(data: &Box<[u8]>) -> u64 {
    let mut hasher = AHasher::default();
    data.hash(&mut hasher);
    hasher.finish()
}

pub async fn stop_liveview(camera_ref: Arc<AsyncMutex<GPhoto2Camera>>) -> Result<()> {
  let camera = camera_ref.lock().await;
  camera.thread_should_stop.store(true, Ordering::SeqCst);

  let join_handle = camera.thread_join_handle.replace(None);
  match join_handle {
    Some(y) => {
      y.abort();
      Ok(())
    },
    None => Ok(()),
  }
}

pub async fn auto_focus(camera_ref: Arc<AsyncMutex<GPhoto2Camera>>) -> Result<()> {
  let camera = camera_ref.lock().await;

  match camera.special_handling {
    GPhoto2CameraSpecialHandling::NikonGeneric | GPhoto2CameraSpecialHandling::NikonDSLR => {
      // Non blocking autofocus
      let opcode = camera.camera.config_key::<TextWidget>("opcode").await?;
      opcode.set_value("0x90C1")?;
      camera.camera.set_config(&opcode).await?;
    },
    _ => {
      // Potentially blocks live view for a moment
      let widget = camera.camera.config_key::<ToggleWidget>("autofocusdrive").await?;
      camera.camera.set_config(&widget).await?;
    },
  }

  Ok(())
}

pub async fn clear_events(camera_ref: Arc<AsyncMutex<GPhoto2Camera>>, download_extra_files: bool) -> Result<()> {
  let camera = camera_ref.lock().await;

  let start = Instant::now();
  let mut n_events = 0;
  loop {
    let event = camera.camera.wait_event(Duration::zero().to_std().unwrap()).await?;
    n_events += 1;
    match event {
      CameraEvent::NewFile(event) => {
        if !download_extra_files {
          debug!("download_extra_files is false, ignoring file: {}/{}", event.folder(), event.name());
        } else if let Some(callback) = &camera.extra_file_callback {
          debug!("Downloading file from camera: {}/{}", event.folder(), event.name());
          let file = camera.camera.fs().download(&event.folder(), &event.name()).await?;
          let data = file.get_data(get_context()?).await?;
          debug!("{}", "Calling extra file callback");
          callback(GPhoto2File {
            source_folder: event.folder().to_string(),
            filename: event.name().to_string(),
            data: data.to_vec(),
          });
        } else {
          debug!("No extra file callback set, ignoring file: {}/{}", event.folder(), event.name());
        }
      },
      CameraEvent::Timeout => break,
      _ => {},
    }
  }

  let elapsed = start.elapsed();
  debug!("Cleared {} events in {}ms", n_events - 1, elapsed.as_millis());

  Ok(())
}

pub async fn set_extra_file_callback<F>(camera_ref: Arc<AsyncMutex<GPhoto2Camera>>, file_data_callback: F) where F: Fn(GPhoto2File) + Send + Sync + 'static {
  let mut camera = camera_ref.lock().await;

  camera.extra_file_callback = Some(Box::new(file_data_callback));
}

pub async fn capture_photo(camera_ref: Arc<AsyncMutex<GPhoto2Camera>>, capture_target_value: String) -> Result<GPhoto2File> {
  let camera = camera_ref.lock().await;

  if !capture_target_value.is_empty() {
    let opcode = camera.camera.config_key::<RadioWidget>("capturetarget").await?;
    opcode.set_choice(&capture_target_value)?;
    camera.camera.set_config(&opcode).await?;
  }

  let capture = camera.camera.capture_image().await?;
  debug!("Downloading file from camera: {}/{}", capture.folder(), capture.name());

  let file = camera.camera.fs().download(&capture.folder(), &capture.name()).await?;
  let data = file.get_data(get_context()?).await?;

  Ok(GPhoto2File {
    source_folder: capture.folder().to_string(),
    filename: capture.name().to_string(),
    data: data.to_vec(),
  })
}

pub struct GPhoto2CameraInfo {
    pub port: String,
    pub model: String,
}

impl GPhoto2CameraInfo {
    pub fn from_camera_descriptor (camera_descriptor: CameraDescriptor) -> Self {
        Self {
            port: camera_descriptor.port,
            model: camera_descriptor.model,
        }
    }
}

pub struct GPhoto2Camera {
  pub camera: Camera,
  pub special_handling: GPhoto2CameraSpecialHandling,
  thread_join_handle: Cell<Option<AsyncJoinHandle<()>>>,
  thread_should_stop: AtomicBool,
  extra_file_callback: Option<Box<dyn Fn(GPhoto2File) + Send + Sync + 'static>>,
}

pub enum GPhoto2CameraSpecialHandling {
  None,
  NikonDSLR,
  NikonGeneric,
  Sony,
}

// ////// //
// Errors //
// ////// //

type Result<T> = std::result::Result<T, Gphoto2Error>;

#[derive(Debug)]
pub enum Gphoto2Error {
  ContextNotInitialized,
  // PoisonError,
  // FrameDecodeError,
  // StopLiveViewThreadError(Box<dyn Any + Send>),
  Gphoto2LibraryError(Error),
}

impl From<Error> for Gphoto2Error {
  fn from(err: Error) -> Gphoto2Error {
    Gphoto2Error::Gphoto2LibraryError(err)
  }
}

pub struct GPhoto2File {
    pub source_folder: String,
    pub filename: String,
    pub data: Vec<u8>,
}

// /////// //
// FRB API //
// /////// //

pub static GPHOTO2_HANDLES: LazyLock<DashMap<u32, Arc<Mutex<GPhoto2CameraHandle>>>> = LazyLock::new(|| DashMap::<u32, Arc<Mutex<GPhoto2CameraHandle>>>::new());

static GPHOTO2_INITIALIZED: AtomicBool = AtomicBool::new(false);

pub fn gphoto2_initialize(iolibs_path: String, camlibs_path: String) {
    if !GPHOTO2_INITIALIZED.load(Ordering::SeqCst) {
        // gPhoto2 has not been initialized yet
        gphoto2::initialize(iolibs_path, camlibs_path).expect("Could not initialize gPhoto2");
        GPHOTO2_INITIALIZED.store(true, Ordering::SeqCst);
        info!("{}", "Initialized gPhoto2");
    } else {
        // Hardware has already been initialized (possible due to Hot Reload)
        debug!("{}", "Possible Hot Reload: Closing open gPhoto2 handles");
        for map_entry in GPHOTO2_HANDLES.iter() {
            TOKIO_RUNTIME.get().expect("Could not get tokio runtime").block_on(async{
                gphoto2::stop_liveview(map_entry.value().lock().camera.clone()).await
            }).expect("Could not get result");
        }
        debug!("{}", "Possible Hot Reload: Closed gPhoto2 handles");
        GPHOTO2_HANDLES.clear();
    }
}

static GPHOTO2_HANDLE_COUNT: AtomicU32 = AtomicU32::new(1);

pub fn gphoto2_get_cameras() -> Vec<GPhoto2CameraInfo> {
    gphoto2::get_cameras().expect("Could not enumerate cameras")
}

pub fn gphoto2_open_camera(model: String, port: String, special_handling: GPhoto2CameraSpecialHandling) -> u32 {
    let camera = TOKIO_RUNTIME.get().expect("Could not get tokio runtime").block_on(async {
        gphoto2::open_camera(model, port, special_handling).await
    }).expect("Could not open camera");

    // Store handle
    let handle_id = GPHOTO2_HANDLE_COUNT.fetch_add(1, Ordering::SeqCst);
    GPHOTO2_HANDLES.insert(handle_id, Arc::new(Mutex::new(GPhoto2CameraHandle::new(camera, vec!()))));

    handle_id
}

pub fn gphoto2_close_camera(handle_id: u32) {
    gphoto2_stop_liveview(handle_id);
    GPHOTO2_HANDLES.remove(&handle_id).expect("Invalid nokhwa handle ID");
}

pub fn gphoto2_start_liveview(handle_id: u32, operations: Vec<ImageOperation>, texture_ptr: usize) {
    let renderer = FlutterTexture::new(texture_ptr, 0, 0);
    let renderer_mutex = Mutex::new(renderer);

    let camera_ref = GPHOTO2_HANDLES.get(&handle_id).expect("Invalid gPhoto2 handle ID");
    let mut camera_handle = camera_ref.lock();
    camera_handle.operations = operations;

    let camera = camera_handle.camera.clone();

    TOKIO_RUNTIME.get().expect("Could not get tokio runtime").block_on(async {
        gphoto2::start_liveview(camera, move |raw_frame| {
            let camera_ref = GPHOTO2_HANDLES.get(&handle_id).expect("Invalid gPhoto2 handle ID");
            let camera_arc = camera_ref.clone();
            let mut camera = camera_arc.lock();

            match raw_frame {
                Ok(raw_frame) => {
                    let processed_frame = image_processing::execute_operations(&raw_frame, &camera.operations);
                    let mut renderer = renderer_mutex.lock();

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
            let camera = camera_arc.lock();
            camera.duplicate_frame_count.fetch_add(1, Ordering::SeqCst);
        }).await
    }).expect("Could not start live view")
}

pub fn gphoto2_set_operations(handle_id: u32, operations: Vec<ImageOperation>) {
    let camera_ref = GPHOTO2_HANDLES.get(&handle_id).expect("Invalid gPhoto2 handle ID");
    let mut camera_handle = camera_ref.lock();
    camera_handle.operations = operations;
}

pub fn gphoto2_stop_liveview(handle_id: u32) {
    let camera_ref = GPHOTO2_HANDLES.get(&handle_id).expect("Invalid gPhoto2 handle ID");
    let camera = camera_ref.clone().lock().camera.clone();

    TOKIO_RUNTIME.get().expect("Could not get tokio runtime").block_on(async{
        gphoto2::stop_liveview(camera).await
    }).expect("Could not get result")
}

pub fn gphoto2_auto_focus(handle_id: u32) {
    let camera_ref: dashmap::mapref::one::Ref<'_, u32, Arc<Mutex<GPhoto2CameraHandle>>> = GPHOTO2_HANDLES.get(&handle_id).expect("Invalid gPhoto2 handle ID");
    let camera = camera_ref.clone().lock().camera.clone();

    TOKIO_RUNTIME.get().expect("Could not get tokio runtime").block_on(async{
        gphoto2::auto_focus(camera).await
    }).expect("Could not get result")
}

pub fn gphoto2_clear_events(handle_id: u32, download_extra_files: bool) {
    let camera_ref = GPHOTO2_HANDLES.get(&handle_id).expect("Invalid gPhoto2 handle ID");
    let camera = camera_ref.clone().lock().camera.clone();

    TOKIO_RUNTIME.get().expect("Could not get tokio runtime").block_on(async{
        gphoto2::clear_events(camera, download_extra_files).await
    }).expect("Could not get result")
}

pub fn gphoto2_capture_photo(handle_id: u32, capture_target_value: String) -> GPhoto2File {
    let camera_ref = GPHOTO2_HANDLES.get(&handle_id).expect("Invalid gPhoto2 handle ID");
    let camera = camera_ref.clone().lock().camera.clone();

    TOKIO_RUNTIME.get().expect("Could not get tokio runtime").block_on(async{
        gphoto2::capture_photo(camera, capture_target_value).await
    }).expect("Could not get result")
}

pub fn gphoto2_get_camera_status(handle_id: u32) -> CameraState {
    let camera_ref = GPHOTO2_HANDLES.get(&handle_id).expect("Invalid gPhoto2 handle ID");
    let camera_arc = camera_ref.clone();
    let camera = camera_arc.lock();

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

pub fn gphoto2_get_last_frame(handle_id: u32) -> Option<RawImage> {
    let camera_ref = GPHOTO2_HANDLES.get(&handle_id).expect("Invalid gPhoto2 handle ID");
    let camera_arc = camera_ref.clone();
    let camera = camera_arc.lock();
    camera.last_valid_frame.clone()
}

pub fn gphoto2_set_extra_file_callback(handle_id: u32, image_sink: StreamSink<GPhoto2File>) {
    let camera_ref = GPHOTO2_HANDLES.get(&handle_id).expect("Invalid gPhoto2 handle ID");
    let camera = camera_ref.clone().lock().camera.clone();

    TOKIO_RUNTIME.get().expect("Could not get tokio runtime").block_on(async{
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
    pub valid_frame_count: AtomicU32,
    pub error_frame_count: AtomicU32,
    pub duplicate_frame_count: AtomicU32,
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
            valid_frame_count: AtomicU32::new(0),
            error_frame_count: AtomicU32::new(0),
            duplicate_frame_count: AtomicU32::new(0),
            last_frame_was_valid: AtomicBool::new(false),
            last_valid_frame: None,
            last_received_frame_timestamp: None,
            operations: operations,
        }
    }
}

impl Drop for GPhoto2CameraHandle {
    fn drop(&mut self) {
        debug!("{}", "Dropping GPhoto2CameraHandle");
    }
}

// ///////////////// //
// Environment stuff //
// ///////////////// //

#[cfg(all(target_os = "windows"))]
fn set_environment_variable(key: &str, value: &str) {
    use libc::putenv;
    use std::ffi::CString;

    // We use this as std::env::set_var does not work on Windows in our case.
    let putenv_str = format!("{}={}", key, value);
    let putenv_cstr =  CString::new(putenv_str).unwrap();
    unsafe { putenv(putenv_cstr.as_ptr()) };
}

#[cfg(not(target_os = "windows"))]
fn set_environment_variable(key: &str, value: &str) {
    use std::env;

    env::set_var(key, value);
}
