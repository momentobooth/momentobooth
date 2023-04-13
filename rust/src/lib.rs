use flutter_rust_bridge::StreamSink;
use hardware_control::live_view::nokhwa;
use once_cell::sync::OnceCell;

mod dart_bridge;
mod hardware_control;
mod utils;

static LOG_STREAM: OnceCell<StreamSink<LogEvent>> = OnceCell::new();

pub fn initialize_log(log_sink: StreamSink<LogEvent>) {
    if LOG_STREAM.get().is_some() {
        return;
    }
    
    let result = LOG_STREAM.set(log_sink);
    if result.is_err() {
        panic!("Could not initialize log stream");
    }
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
    LOG_STREAM.get().expect("Could not get log stream").add(message);
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
