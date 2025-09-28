use crate::frb_generated::StreamSink;
use crate::models::logging::LogEntry;
use crate::models::version_info::VersionInfo;
use std::path::Path;
use std::time;
use crate::INITIALIZATION;
use crate::LIBRARY_VERSION;
use crate::RUST_TARGET;
use crate::TOKIO_RUNTIME;
pub use ipp::model::PrinterState;
pub use ipp::model::JobState;
use log::LevelFilter;
use parking_lot::RwLock;
use tokio::runtime;
use rustc_version_runtime::version;
use libusb_sys::libusb_get_version;

use super::noise::noise_close;
use super::noise::NOISE_HANDLES;
use log::{debug, info};

// ////////////// //
// Initialization //
// ////////////// //

pub fn get_version_info() -> VersionInfo {
    VersionInfo {
        rust_version: version().to_string(),
        rust_target: RUST_TARGET.to_owned(),
        library_version: LIBRARY_VERSION.to_owned(),
        libgphoto2_version: ::gphoto2::library_version().unwrap().to_owned(),
        libusb_version: get_libusb_version(),
    }
}

fn get_libusb_version() -> String {
    unsafe {
        let libusb_version = libusb_get_version();
        format!("{}.{}.{}", (*libusb_version).major, (*libusb_version).minor, (*libusb_version).micro)
    }
}

// /////// //
// Logging //
// /////// //

static START: RwLock<Option<time::Instant>> = RwLock::new(None);
static LOG_SINK: RwLock<Option<StreamSink<LogEntry>>> = RwLock::new(None);

#[must_use]
fn get_lbl(path: &str) -> &str {
    let filename = Path::new(path).file_name().unwrap().to_str().unwrap();
    &filename[..filename.len() - 3]
}

struct FlutterLogger {}

impl log::Log for FlutterLogger {
    fn enabled(&self, metadata: &log::Metadata) -> bool {
        metadata.level() <= log::max_level()
    }

    fn log(&self, record: &log::Record) {
        if !self.enabled(record.metadata()) {
            return;
        }

        let start = START.read().unwrap();
        if LOG_SINK.is_locked_exclusive() {
            println!("LOG_SINK locked, but line is: {}", &std::fmt::format(record.args().to_owned()));
            return;
        }

        LOG_SINK.read().clone().unwrap().add(LogEntry {
            #[allow(clippy::cast_possible_truncation)]
            time_millis: start.elapsed().as_millis() as i64,
            msg: String::from(&std::fmt::format(record.args().to_owned())),
            log_level: record.level(),
            lbl: String::from(record.file().map_or("unknown", get_lbl)),
        }).unwrap();
    }

    fn flush(&self) {}
}

pub fn initialize_log(log_sink: StreamSink<LogEntry>) {
    if LOG_SINK.read().is_none() {
        let logger = FlutterLogger {};
        let _ = log::set_boxed_logger(Box::new(logger)).map(|()| log::set_max_level(LevelFilter::Trace)).unwrap();
    }

    *START.write() = Some(time::Instant::now());
    *LOG_SINK.write() = Some(log_sink);

    info!("Logging initialized");
}

// Important note: This function should be allowed to run multiple times.
// This should only happen when Hot Restart has been invoked on the Flutter app.
pub fn initialize_library() {
    debug!("{}", "Helper library initialization started");

    INITIALIZATION.call_once(|| {
        // TODO: test what happens when we panic
        TOKIO_RUNTIME.get_or_init(|| runtime::Builder::new_multi_thread().enable_all().build().unwrap());
        debug!("{}", "Tokio runtime initialized");
    });

    while !NOISE_HANDLES.is_empty() {
        debug!("{}", "Possible Hot Reload: Closing noise handle");
        let id = NOISE_HANDLES.iter().next().unwrap().key().to_owned();
        noise_close(id);
        NOISE_HANDLES.remove(&id);
        debug!("{}", "Possible Hot Reload: Closed noise handle");
    }

    info!("{}", "Helper library initialization done");
}
