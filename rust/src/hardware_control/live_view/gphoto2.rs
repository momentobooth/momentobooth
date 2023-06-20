use std::thread;

use gphoto2::{Context, list::CameraDescriptor, widget::TextWidget};

use crate::{utils::jpeg, dart_bridge::api::RawImage};

pub fn get_cameras() -> Vec<Gphoto2CameraInfo> {
  //env_logger::init();

  let context = Context::new().expect("Could not create gphoto2 context");

  println!("Available cameras:");
  let mut cameras: Vec<Gphoto2CameraInfo> = Vec::new();
  for CameraDescriptor { model, port } in context.list_cameras().wait().expect("Could not list cameras") {
    cameras.push(Gphoto2CameraInfo::from_camera_descriptor(CameraDescriptor { model, port }));
  }

  cameras
}

pub fn open_camera_liveview<F>(model: String, port: String, frame_callback: F) where F: Fn(Option<RawImage>) + Send + Sync + 'static {
  let context = Context::new().expect("Could not create gphoto2 context");

  let camera = context.get_camera(&CameraDescriptor { model, port }).wait().expect("Could not open camera");
  let opcode = camera.config_key::<TextWidget>("opcode").wait().expect("Could not get opcode");

  println!("Starting live view");
  opcode.set_value("0x9201").expect("Could not set opcode");
  camera.set_config(&opcode).wait().expect("Could not set opcode");

  thread::spawn(move || {
    loop {
      let preview = camera.capture_preview().wait().expect("Could not capture preview");
      let data = preview.get_data(&context).wait().expect("Could not get preview data");
      let raw_image = jpeg::decode_jpeg_to_rgba(&data); // TODO: Handle errors (this should return Option<RawImage>)
      frame_callback(Some(raw_image))
    }
  });
}

pub struct Gphoto2CameraInfo {
    pub port: String,
    pub model: String,
}

impl Gphoto2CameraInfo {
    pub fn from_camera_descriptor (camera_descriptor: CameraDescriptor) -> Self {
        Self {
            port: camera_descriptor.port,
            model: camera_descriptor.model,
        }
    }
}
