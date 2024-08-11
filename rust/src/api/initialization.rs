use crate::hardware_control::live_view::gphoto2;
use crate::hardware_control::live_view::gphoto2::GPHOTO2_HANDLES;
use crate::hardware_control::live_view::nokhwa::NOKHWA_HANDLES;
use std::sync::atomic::{Ordering, AtomicBool};

pub use ipp::model::PrinterState;
pub use ipp::model::JobState;

use crate::{frb_generated::StreamSink, helpers::{self, HardwareInitializationFinishedEvent, TOKIO_RUNTIME}};

use super::noise::noise_close;
use super::noise::NOISE_HANDLES;

use log::debug;

flutter_logger::flutter_logger_init!();

// ////////////// //
// Initialization //
// ////////////// //

static HARDWARE_INITIALIZED: AtomicBool = AtomicBool::new(false);

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
