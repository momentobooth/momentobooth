use parking_lot::RwLock;
use crate::{frb_generated::StreamSink, models::logging::*};

pub static LOG_STREAM: RwLock<Option<StreamSink<LogEvent>>> = RwLock::new(None);

pub fn log_event(event: LogEvent) {
    let log_sink = LOG_STREAM.read().clone().expect("Could not acquire read lock");
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
