use std::sync::Mutex;

use atom_table::AtomTable;
use derive_more::{From, Into};
use nokhwa::{utils::{CameraInfo}, query, native_api_backend, nokhwa_initialize};
use once_cell::sync::Lazy;

pub fn initialize<F>(on_complete: F) where F: Fn(bool) + std::marker::Send + std::marker::Sync + 'static {
    if cfg!(target_os = "macos") {
        nokhwa_initialize(on_complete);
    } else {
        on_complete(true);
    }
}

pub fn get_cameras() -> Vec<NokhwaCameraInfo> {
    let backend = native_api_backend().unwrap();
    let devices = query(backend).unwrap();

    let device_names: Vec<NokhwaCameraInfo> = devices.iter().map(|d| NokhwaCameraInfo::from_camera_info(d)).collect();
    return device_names;
}

pub fn open_camera() {

}

// //////////////////////// //
// Nokhwa handle management //
// //////////////////////// //

static OPEN_CAMERAS: Lazy<Mutex<AtomTable<String, Id>>> = Lazy::new(|| Mutex::new(AtomTable::new()));

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, From, Into)]
struct Id(usize);

// /////// //
// Structs //
// /////// //

pub struct NokhwaCameraInfo {
    pub id: u32,
    pub friendly_name: String,
}

impl NokhwaCameraInfo {
    pub fn from_camera_info(camera_info: &CameraInfo) -> Self {
        Self { id: camera_info.index().as_index().unwrap(), friendly_name: camera_info.human_name() }
    }
}
