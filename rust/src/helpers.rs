use std::sync::OnceLock;

use crate::hardware_control::live_view::nokhwa;
use tokio::runtime::{self, Runtime};
use crate::{frb_generated::StreamSink, hardware_control::live_view::gphoto2};
use log::debug;

pub static TOKIO_RUNTIME: OnceLock<Runtime> = OnceLock::new();

pub fn initialize_hardware(ready_sink: StreamSink<HardwareInitializationFinishedEvent>) {
    debug!("{}", "initialize_hardware() started");

    // Tokio runtime
    TOKIO_RUNTIME.get_or_init(|| runtime::Builder::new_multi_thread().enable_all().build().unwrap());

    // gphoto2 initialize
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
