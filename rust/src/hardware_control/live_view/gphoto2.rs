use std::{sync::{OnceLock, atomic::{AtomicBool, Ordering}, Arc}, cell::Cell, time::{Duration, Instant}, hash::{Hash, Hasher}};

use ahash::AHasher;
use gphoto2::{camera::CameraEvent, list::CameraDescriptor, widget::{RadioWidget, TextWidget, ToggleWidget}, Camera, Context, Error};

use tokio::{sync::Mutex as AsyncMutex, time::sleep};
use tokio::task::JoinHandle as AsyncJoinHandle;

use crate::{api::simple::RawImage, helpers::log_debug, utils::jpeg};

static CONTEXT: OnceLock<Context> = OnceLock::new();

fn get_context() -> Result<&'static Context> {
  CONTEXT.get().ok_or(Gphoto2Error::ContextNotInitialized)
}

pub fn initialize() -> Result<()> {
  if CONTEXT.get().is_some() {
    // Already initialized
    return Ok(())
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
      let preview = camera.camera.capture_preview().await.expect("Could not capture preview");
      drop(camera);

      let data = preview.get_data(&context).await.expect("Could not get preview data");
      let hash = hash_box(&data);
      if hash == last_hash.get() {
        // Frame is the same as the last one, skip
        duplicate_frame_callback();
        sleep(Duration::from_millis(8)).await;
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
    let event = camera.camera.wait_event(Duration::ZERO).await?;
    n_events += 1;
    match event {
      CameraEvent::NewFile(event) => {
        if !download_extra_files {
          log_debug(format!("download_extra_files is false, ignoring file: {}/{}", event.folder(), event.name()));
        } else if let Some(callback) = &camera.extra_file_callback {
          log_debug(format!("Downloading file from camera: {}/{}", event.folder(), event.name()));
          let file = camera.camera.fs().download(&event.folder(), &event.name()).await?;
          let data = file.get_data(get_context()?).await?;
          log_debug(format!("Calling extra file callback"));
          callback(GPhoto2File {
            source_folder: event.folder().to_string(),
            filename: event.name().to_string(),
            data: data.to_vec(),
          });
        } else {
          log_debug(format!("No extra file callback set, ignoring file: {}/{}", event.folder(), event.name()));
        }
      },
      CameraEvent::Timeout => break,
      _ => {},
    }
  }

  let elapsed = start.elapsed();
  log_debug(format!("Cleared {} events in {}ms", n_events - 1, elapsed.as_millis()));

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
  log_debug(format!("Downloading file from camera: {}/{}", capture.folder(), capture.name()));
  
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
