use std::{sync::RwLock};

use flutter_rust_bridge::StreamSink;
use hardware_control::live_view::nokhwa;

mod dart_bridge;
mod hardware_control;
mod utils;

static LOG_STREAM: RwLock<Option<StreamSink<LogEvent>>> = RwLock::new(None);

pub fn initialize_log(log_sink: StreamSink<LogEvent>) {
    let log_write = LOG_STREAM.write();
    *log_write.expect("Err") = Some(log_sink);
}

pub fn initialize_hardware(ready_sink: StreamSink<HardwareInitializationFinishedEvent>) {
    log("Initializing Rust library".to_string());

    // Nokhwa initialize
    nokhwa::initialize(move |success| {
        let step = HardwareInitializationFinishedEvent {
            step: HardwareInitializationStep::Nokhwa,
            has_succeeded: success,
            message: String::new(),
        };
        ready_sink.add(step);
    });
}

pub fn log(message: String) {
    let message = LogEvent { message };
    let read_guard = LOG_STREAM.read().expect("Could not acquire read lock");
    let log_sink = read_guard.as_ref().expect("Expected log stream to be initialized");
    log_sink.add(message);
}

// /////// //
// Structs //
// /////// //

#[derive(Debug, Clone)]
pub struct LogEvent {
    pub message: String,
}

#[derive(Debug, Clone)]
pub struct HardwareInitializationFinishedEvent {
    pub step: HardwareInitializationStep,
    pub has_succeeded: bool,
    pub message: String,
}

#[derive(Debug, Clone)]
pub enum HardwareInitializationStep {
    Nokhwa,
}
