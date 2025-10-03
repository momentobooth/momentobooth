use std::sync::OnceLock;

use parking_lot::Once;
use pathsep::{path_separator, join_path};
use tokio::runtime::Runtime;

pub mod api;
pub mod models;
mod frb_generated;
mod hardware_control;
mod utils;

const RUST_TARGET: &str = include_str!(join_path!(env!("OUT_DIR"), "target_name.txt"));
const LIBRARY_VERSION: &'static str = env!("CARGO_PKG_VERSION");

pub(crate) static INITIALIZATION: Once = Once::new();

pub(crate) static TOKIO_RUNTIME: OnceLock<Runtime> = OnceLock::new();
