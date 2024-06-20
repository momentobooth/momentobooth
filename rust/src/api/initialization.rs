use crate::logging::*;
use crate::models::version_info::VersionInfo;
use crate::INITIALIZATION;
use crate::RUST_COMPILER_TARGET;
use crate::TOKIO_RUNTIME;
pub use ipp::model::PrinterState;
pub use ipp::model::JobState;
use tokio::runtime;
use rustc_version_runtime::version;

use super::noise::noise_close;
use super::noise::NOISE_HANDLES;

// ////////////// //
// Initialization //
// ////////////// //

// Important note: This function should be allowed to run multiple times.
// This should only happen when Hot Restart has been invoked on the Flutter app.
pub fn initialize_library() -> VersionInfo {
    log_debug("Helper library initialization started".to_owned());

    INITIALIZATION.call_once(|| {
        // TODO: test what happens when we panic
        TOKIO_RUNTIME.get_or_init(|| runtime::Builder::new_multi_thread().enable_all().build().unwrap());
        log_debug("Tokio runtime initialized".to_owned());
        rexiv2::initialize().expect("Unable to initialize rexiv2");
        log_debug("Rexiv2 initialized".to_owned());
    });

    if !NOISE_HANDLES.is_empty() {
        log_debug("Possible Hot Reload: Closing noise handles".to_string());
        for map_entry in NOISE_HANDLES.iter() {
            noise_close(*map_entry.key());
        }
        NOISE_HANDLES.clear();
        log_debug("Possible Hot Reload: Closed noise handles".to_string());
    }

    log_info("Helper library initialization done".to_owned());
    VersionInfo {
        rust_version: version().to_string(),
        rust_target: RUST_COMPILER_TARGET.to_owned(),
    }
}
