use crate::frb_generated::StreamSink;
use crate::models::logging::LogEntry;
use crate::models::version_info::VersionInfo;
use std::ffi::CStr;
use std::path::Path;
use std::time;
use crate::INITIALIZATION;
use crate::LIBRARY_VERSION;
use crate::RUST_TARGET;
use crate::TOKIO_RUNTIME;
use gexiv2_sys::gexiv2_get_version;
pub use ipp::model::PrinterState;
pub use ipp::model::JobState;
use log::LevelFilter;
use parking_lot::RwLock;
use tokio::runtime;
use rustc_version_runtime::version;

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
        libgexiv2_version: get_gexiv2_version(),
        libexiv2_version: get_exiv2_version(),
    }
}

fn get_gexiv2_version() -> String {
    let raw_version = unsafe { gexiv2_get_version() };
    println!("{:?}", raw_version);

    // Extract the major, minor, and patch versions
    let major = raw_version / 10000;
    let minor = (raw_version / 100) % 100;
    let patch = raw_version % 100;

    format!("{}.{}.{}", major, minor, patch)
}

fn get_exiv2_version() -> String {
    return unsafe {
        let c_str = crate::Exiv2_version();
        CStr::from_ptr(c_str).to_string_lossy().into_owned()
    };
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
        rexiv2::initialize().expect("Unable to initialize rexiv2");
        debug!("{}", "Rexiv2 initialized");
    });

    if !NOISE_HANDLES.is_empty() {
        debug!("{}", "Possible Hot Reload: Closing noise handles");
        for map_entry in NOISE_HANDLES.iter() {
            noise_close(*map_entry.key());
        }
        NOISE_HANDLES.clear();
        debug!("{}", "Possible Hot Reload: Closed noise handles");
    }

    info!("{}", "Helper library initialization done");
}
