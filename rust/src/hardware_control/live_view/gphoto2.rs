use std::{thread::{self, JoinHandle}, sync::{OnceLock, atomic::{AtomicBool, Ordering}}, any::Any, rc::Rc};

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
    thread_join_handle: None,
    thread_should_stop: AtomicBool::new(false),
  })
}

pub fn start_liveview<F>(camera: &mut GPhoto2Camera, frame_callback: F) -> Result<()> where F: Fn(Result<RawImage>) + Send + Sync + 'static {
  let opcode = camera.camera.config_key::<TextWidget>("opcode").wait().expect("Could not get opcode");

  match camera.special_handling {
    GPhoto2CameraSpecialHandling::None => {},
    GPhoto2CameraSpecialHandling::NikonDSLR => {
      opcode.set_value("0x9201")?;
      camera.camera.set_config(&opcode).wait()?;
    },
  }
  
  let join_handle = thread::spawn(move || {
    let context = get_context().expect("TODO: handle this");

    loop {
      let preview = camera.camera.capture_preview().wait().expect("Could not capture preview");
      let data = preview.get_data(&context).wait().expect("Could not get preview data");
      let raw_image = jpeg::decode_jpeg_to_rgba(&data); // TODO: Handle errors (this should return Option<RawImage>)
      frame_callback(Ok(raw_image))
    }
  });

  camera.thread_join_handle = Some(join_handle);

  Ok(())
}

pub fn stop_liveview(camera: &GPhoto2Camera) -> Result<()> {
  camera.thread_should_stop.store(true, Ordering::SeqCst);
  camera.thread_join_handle.map_or_else( ||Ok(()), |handle| handle.join().map_err(|error| Gphoto2Error::StopLiveViewThreadError(error)))
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
  thread_join_handle: Option<JoinHandle<()>>,
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
  FrameDecodeError,
  StopLiveViewThreadError(Box<dyn Any + Send>),
  Gphoto2LibraryError(Error),
}

impl From<Error> for Gphoto2Error {
  fn from(err: Error) -> Gphoto2Error {
    Gphoto2Error::Gphoto2LibraryError(err)
  }
}
