use std::{thread::{self, JoinHandle}, sync::{OnceLock, atomic::{AtomicBool, Ordering}, Arc, Mutex, PoisonError, MutexGuard}, any::Any, cell::Cell, path::Path};

use gphoto2::{Context, list::CameraDescriptor, widget::TextWidget, Camera, Error};

use crate::{utils::jpeg, dart_bridge::api::RawImage};

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

pub fn open_camera(model: String, port: String, special_handling: GPhoto2CameraSpecialHandling) -> Result<GPhoto2Camera> {
  let camera = get_context()?.get_camera(&CameraDescriptor { model, port }).wait()?;

  Ok(GPhoto2Camera {
    camera,
    special_handling,
    thread_join_handle: Cell::new(None),
    thread_should_stop: AtomicBool::new(false),
  })
}

pub fn start_liveview<F>(camera_ref: Arc<Mutex<GPhoto2Camera>>, frame_callback: F) -> Result<()> where F: Fn(Result<RawImage>) + Send + Sync + 'static {
  let mut camera = camera_ref.lock().expect("Could not lock camera");

  // TODO: check if join handle not already set


  match camera.special_handling {
    GPhoto2CameraSpecialHandling::None => {},
    GPhoto2CameraSpecialHandling::NikonDSLR => {
      let opcode = camera.camera.config_key::<TextWidget>("opcode").wait()?;
      opcode.set_value("0x9201")?;
      camera.camera.set_config(&opcode).wait()?;
    },
  }
  
  let camera_ref = camera_ref.clone();
  let join_handle = thread::spawn(move || {
    let context = get_context().expect("TODO: handle this");

    loop {
      let camera = camera_ref.lock().expect("Could not lock camera");
      let preview = camera.camera.capture_preview().wait().expect("Could not capture preview");
      drop(camera);

      let data = preview.get_data(&context).wait().expect("Could not get preview data");
      let raw_image = jpeg::decode_jpeg_to_rgba(&data); // TODO: Handle errors (this should return Option<RawImage>)
      frame_callback(Ok(raw_image))
    }
  });

  camera.thread_join_handle = Cell::new(Some(join_handle));

  Ok(())
}

pub fn stop_liveview(camera_ref: Arc<Mutex<GPhoto2Camera>>) -> Result<()> {
  let camera = camera_ref.lock().expect("Could not lock camera");
  camera.thread_should_stop.store(true, Ordering::SeqCst);

  let join_handle = camera.thread_join_handle.replace(None);
  match join_handle {
    Some(y) => {
      y.join();
      Ok(())
    },
    None => Ok(()),
  }
}

pub fn capture_photo(camera_ref: Arc<Mutex<GPhoto2Camera>>) -> Result<Vec<u8>> {
  let camera = camera_ref.lock().expect("Could not lock camera");
  let capture = camera.camera.capture_image().wait()?;
  
  let file = camera.camera
    .fs()
    .download(&capture.folder(), &capture.name())
    .wait()?;
  let data = file.get_data(get_context()?).wait()?;

  Ok(data.to_vec())
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
  thread_join_handle: Cell<Option<JoinHandle<()>>>,
  thread_should_stop: AtomicBool,
}

pub enum GPhoto2CameraSpecialHandling {
  None,
  NikonDSLR,
}

// ////// //
// Errors //
// ////// //

type Result<T> = std::result::Result<T, Gphoto2Error>;

#[derive(Debug)]
pub enum Gphoto2Error {
  ContextNotInitialized,
  PoisonError,
  FrameDecodeError,
  StopLiveViewThreadError(Box<dyn Any + Send>),
  Gphoto2LibraryError(Error),
}

impl From<Error> for Gphoto2Error {
  fn from(err: Error) -> Gphoto2Error {
    Gphoto2Error::Gphoto2LibraryError(err)
  }
}
