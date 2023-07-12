use std::{sync::{RwLock, OnceLock}};

use flutter_rust_bridge::StreamSink;
use hardware_control::live_view::{nokhwa};
use pathsep::{path_separator, join_path};
use tokio::runtime::{self, Runtime};
use crate::hardware_control::live_view::gphoto2;

mod dart_bridge;
mod hardware_control;
mod utils;

const TARGET: &str = include_str!(join_path!(env!("OUT_DIR"), "target_name.txt"));

static LOG_STREAM: RwLock<Option<StreamSink<LogEvent>>> = RwLock::new(None);

static TOKIO_RUNTIME: OnceLock<Runtime> = OnceLock::new();

pub fn initialize_log(log_sink: StreamSink<LogEvent>) {
    let log_write = LOG_STREAM.write();
    *log_write.expect("Err") = Some(log_sink);

    log_debug("Native library compiled with target ".to_string() + TARGET)
}

pub fn initialize_hardware(ready_sink: StreamSink<HardwareInitializationFinishedEvent>) {
    log_debug("initialize_hardware() started".to_string());

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
        log_debug("initialize_hardware() nokhwa init result: ".to_string() + &success.to_string());
        ready_sink.add(HardwareInitializationFinishedEvent {
            step: HardwareInitializationStep::Nokhwa,
            has_succeeded: success,
            message: String::new(),
        });
    });

    log_debug("initialize_hardware() ended".to_string());
}

pub fn log_event(event: LogEvent) {
    let read_guard = LOG_STREAM.read().expect("Could not acquire read lock");
    let log_sink = read_guard.as_ref().expect("Expected log stream to be initialized");
    log_sink.add(event);
}

// /////// //
// Helpers //
// /////// //

pub fn log_debug(message: String) {
    log_event(LogEvent { message, level: LogLevel::Debug })
}

pub fn log_info(message: String) {
    log_event(LogEvent { message, level: LogLevel::Info })
}

pub fn log_warning(message: String) {
    log_event(LogEvent { message, level: LogLevel::Warning })
}

pub fn log_error(message: String) {
    log_event(LogEvent { message, level: LogLevel::Error })
}


// /////// //
// Structs //
// /////// //

#[derive(Debug, Clone)]
pub struct LogEvent {
    pub message: String,
    pub level: LogLevel,
}

#[derive(Debug, Clone)]
pub enum LogLevel {
    Debug,
    Info,
    Warning,
    Error,
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
    Gphoto2,
}
