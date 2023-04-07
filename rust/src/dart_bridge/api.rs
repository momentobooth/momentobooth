use flutter_rust_bridge::StreamSink;

use crate::{hardware_control::live_view::nokhwa::{self, NokhwaCameraInfo}, LogEvent, HardwareInitializationFinishedEvent};

pub fn initialize_log(log_sink: StreamSink<LogEvent>) {
    crate::initialize_log(log_sink);
}

pub fn initialize_hardware(ready_sink: StreamSink<HardwareInitializationFinishedEvent>) {
    crate::initialize_hardware(ready_sink);
}

pub fn nokhwa_get_cameras() -> Vec<NokhwaCameraInfo> {
    return nokhwa::get_cameras();
}
