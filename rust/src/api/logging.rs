use crate::{frb_generated::StreamSink, logging::LOG_STREAM, models::logging::LogEvent};

// ////////////// //
// Initialization //
// ////////////// //

pub fn initialize_logging(log_sink: StreamSink<LogEvent>) {
    let mut log_stream = LOG_STREAM.write();
    *log_stream = Some(log_sink);
}
