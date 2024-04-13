use crate::hardware_control::live_view::gphoto2;
use std::sync::atomic::{Ordering, AtomicBool};

pub use ipp::model::PrinterState;
pub use ipp::model::JobState;

use crate::{frb_generated::StreamSink, helpers::{self, log_debug, HardwareInitializationFinishedEvent, LogEvent, TOKIO_RUNTIME}};

use super::gphoto2::GPHOTO2_HANDLES;
use super::noise::noise_close;
use super::noise::NOISE_HANDLES;
use super::nokhwa::NOKHWA_HANDLES;

// ////////////// //
// Initialization //
// ////////////// //

static HARDWARE_INITIALIZED: AtomicBool = AtomicBool::new(false);

pub fn initialize_log(log_sink: StreamSink<LogEvent>) {
    helpers::initialize_log(log_sink);
}

pub fn initialize_hardware(ready_sink: StreamSink<HardwareInitializationFinishedEvent>) {
    rexiv2::initialize().expect("Unable to initialize rexiv2");
    if !HARDWARE_INITIALIZED.load(Ordering::SeqCst) {
        // Hardware has not been initialized yet
        helpers::initialize_hardware(ready_sink);
        HARDWARE_INITIALIZED.store(true, Ordering::SeqCst);
    } else {
        // Hardware has already been initialized (possible due to Hot Reload)
        log_debug("Possible Hot Reload: Closing any open cameras and noise generators".to_string());
        for map_entry in NOKHWA_HANDLES.iter() {
            map_entry.value().lock().expect("Could not lock on handle").camera.set_callback(|_| {}).expect("Stream close error");
        }
        log_debug("Possible Hot Reload: Closed nokhwa".to_string());
        NOKHWA_HANDLES.clear();
        for map_entry in GPHOTO2_HANDLES.iter() {
            TOKIO_RUNTIME.get().expect("Could not get tokio runtime").block_on(async{
                gphoto2::stop_liveview(map_entry.value().lock().expect("Could not lock camera").camera.clone()).await
            }).expect("Could not get result");
        }
        log_debug("Possible Hot Reload: Closed gphoto2".to_string());
        GPHOTO2_HANDLES.clear();
        for map_entry in NOISE_HANDLES.iter() {
            noise_close(*map_entry.key());
        }
        log_debug("Possible Hot Reload: Closed noise".to_string());
    }
}
