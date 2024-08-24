use crate::hardware_control::live_view::gphoto2::{self, GPHOTO2_HANDLES};
use crate::hardware_control::live_view::nokhwa::NOKHWA_HANDLES;
use crate::models::version_info::VersionInfo;
use std::sync::atomic::{Ordering, AtomicBool};
use gexiv2_sys::gexiv2_get_version;
pub use ipp::model::PrinterState;
pub use ipp::model::JobState;
use crate::{frb_generated::StreamSink, helpers::{self, HardwareInitializationFinishedEvent, TOKIO_RUNTIME}};
use super::noise::noise_close;
use super::noise::NOISE_HANDLES;
use log::debug;
use rustc_version_runtime::version;
use pathsep::{path_separator, join_path};

flutter_logger::flutter_logger_init!();

const RUST_COMPILE_TARGET: &str = include_str!(join_path!(env!("OUT_DIR"), "target_name.txt"));
const LIBRARY_VERSION: &'static str = env!("CARGO_PKG_VERSION");

// ////////////// //
// Initialization //
// ////////////// //

static HARDWARE_INITIALIZED: AtomicBool = AtomicBool::new(false);

pub fn get_version_info() -> VersionInfo {
    VersionInfo {
        rust_version: version().to_string(),
        rust_target: RUST_COMPILE_TARGET.to_owned(),
        library_version: LIBRARY_VERSION.to_owned(),
        libgphoto2_version: ::gphoto2::library_version().unwrap().to_owned(),
        libgexiv2_version: get_gexiv2_version(),
    }
}

fn get_gexiv2_version() -> String {
    let raw_version = unsafe { gexiv2_get_version() };
    println!("{:?}", raw_version);

    // Extract the major, minor, and patch versions
    let major = raw_version / 10000;
    let minor = (raw_version / 100) % 100;
    let patch = raw_version % 100;

    format!("{}.{}.{}", major, minor, patch)
}

pub fn initialize_hardware(ready_sink: StreamSink<HardwareInitializationFinishedEvent>) {
    rexiv2::initialize().expect("Unable to initialize rexiv2");
    if !HARDWARE_INITIALIZED.load(Ordering::SeqCst) {
        // Hardware has not been initialized yet
        helpers::initialize_hardware(ready_sink);
        HARDWARE_INITIALIZED.store(true, Ordering::SeqCst);
    } else {
        // Hardware has already been initialized (possible due to Hot Reload)
        debug!("{}", "Possible Hot Reload: Closing any open cameras and noise generators");
        for map_entry in NOKHWA_HANDLES.iter() {
            map_entry.value().lock().expect("Could not lock on handle").camera.set_callback(|_| {}).expect("Stream close error");
        }
        debug!("{}", "Possible Hot Reload: Closed nokhwa");
        NOKHWA_HANDLES.clear();
        for map_entry in GPHOTO2_HANDLES.iter() {
            TOKIO_RUNTIME.get().expect("Could not get tokio runtime").block_on(async{
                gphoto2::stop_liveview(map_entry.value().lock().expect("Could not lock camera").camera.clone()).await
            }).expect("Could not get result");
        }
        debug!("{}", "Possible Hot Reload: Closed gphoto2");
        GPHOTO2_HANDLES.clear();
        for map_entry in NOISE_HANDLES.iter() {
            noise_close(*map_entry.key());
        }
        debug!("{}", "Possible Hot Reload: Closed noise");
    }
}
