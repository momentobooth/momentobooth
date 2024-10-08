use std::{env, ffi::CString, sync::OnceLock};

use crate::hardware_control::live_view::nokhwa;
use libc::putenv;
use tokio::runtime::{self, Runtime};
use crate::{frb_generated::StreamSink, hardware_control::live_view::gphoto2};
use log::debug;

pub static TOKIO_RUNTIME: OnceLock<Runtime> = OnceLock::new();

fn set_environment_variable(key: &str, value: &str) {
    // We use this as std::env::set_var does not work on Windows in our case.
    let putenv_str = format!("{}={}", key, value);
    let putenv_cstr =  CString::new(putenv_str).unwrap();
    unsafe { putenv(putenv_cstr.as_ptr() as *mut i8) };
}

pub fn initialize_hardware(iolibs_path: String, camlibs_path: String, ready_sink: StreamSink<HardwareInitializationFinishedEvent>) {
    debug!("{}", "initialize_hardware() started");

    // Tokio runtime
    TOKIO_RUNTIME.get_or_init(|| runtime::Builder::new_multi_thread().enable_all().build().unwrap());

    // gPhoto2 initialize
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

    let initialize_result = gphoto2::initialize();
    ready_sink.add(HardwareInitializationFinishedEvent {
        step: HardwareInitializationStep::Gphoto2,
        has_succeeded: initialize_result.is_ok(),
        message: String::new(),
    });

    // Nokhwa initialize
    nokhwa::initialize(move |success| {
        debug!("initialize_hardware() nokhwa init result: {}", &success);
        ready_sink.add(HardwareInitializationFinishedEvent {
            step: HardwareInitializationStep::Nokhwa,
            has_succeeded: success,
            message: String::new(),
        });
    });

    debug!("{}", "initialize_hardware() ended");
}

// /////// //
// Structs //
// /////// //

#[derive(Debug, Clone)]
pub struct HardwareInitializationFinishedEvent {
    pub step: HardwareInitializationStep,
    pub has_succeeded: bool,
    pub message: String,
}

#[derive(Debug, Clone)]
pub enum HardwareInitializationStep {
    Nokhwa,
    Gphoto2,
}
