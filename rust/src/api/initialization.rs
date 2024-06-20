use crate::models::version_info::VersionInfo;
use std::ffi::CStr;
use crate::INITIALIZATION;
use crate::LIBRARY_VERSION;
use crate::RUST_TARGET;
use crate::TOKIO_RUNTIME;
use gexiv2_sys::gexiv2_get_version;
pub use ipp::model::PrinterState;
pub use ipp::model::JobState;
use tokio::runtime;
use rustc_version_runtime::version;

use super::noise::noise_close;
use super::noise::NOISE_HANDLES;
use log::{debug, info, LevelFilter};
use rustc_version_runtime::version;

flutter_logger::flutter_logger_init!(LevelFilter::Trace);

// ////////////// //
// Initialization //
// ////////////// //

pub fn get_version_info() -> VersionInfo {
    VersionInfo {
        rust_version: version().to_string(),
        rust_target: RUST_TARGET.to_owned(),
        library_version: LIBRARY_VERSION.to_owned(),
        libgphoto2_version: ::gphoto2::library_version().unwrap().to_owned(),
        libgexiv2_version: get_gexiv2_version(),
        libexiv2_version: get_exiv2_version(),
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

fn get_exiv2_version() -> String {
    return unsafe {
        let c_str = crate::Exiv2_version();
        CStr::from_ptr(c_str).to_string_lossy().into_owned()
    };
}

// Important note: This function should be allowed to run multiple times.
// This should only happen when Hot Restart has been invoked on the Flutter app.
#[frb(init)]
pub fn initialize_library() {
    debug!("{}", "Helper library initialization started");

    INITIALIZATION.call_once(|| {
        // TODO: test what happens when we panic
        TOKIO_RUNTIME.get_or_init(|| runtime::Builder::new_multi_thread().enable_all().build().unwrap());
        debug!("{}", "Tokio runtime initialized");
        rexiv2::initialize().expect("Unable to initialize rexiv2");
        debug!("{}", "Rexiv2 initialized");
    });

    if !NOISE_HANDLES.is_empty() {
        debug!("{}", "Possible Hot Reload: Closing noise handles");
        for map_entry in NOISE_HANDLES.iter() {
            noise_close(*map_entry.key());
        }
        NOISE_HANDLES.clear();
        debug!("{}", "Possible Hot Reload: Closed noise handles");
    }

    info!("{}", "Helper library initialization done");
}

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
