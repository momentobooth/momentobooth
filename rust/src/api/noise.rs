use std::sync::atomic::{AtomicUsize, Ordering};

use dashmap::DashMap;
pub use ipp::model::PrinterState;
pub use ipp::model::JobState;
use turborand::rng::Rng;

use crate::{hardware_control::live_view::white_noise::{self, WhiteNoiseGeneratorHandle}, helpers::log_debug, models::images::RawImage, utils::flutter_texture::FlutterTexture};
 
lazy_static::lazy_static! {
    pub static ref NOISE_HANDLES: DashMap<usize, WhiteNoiseGeneratorHandle> = DashMap::<usize, WhiteNoiseGeneratorHandle>::new();
}

static NOISE_HANDLE_COUNT: AtomicUsize = AtomicUsize::new(1);

const NOISE_WIDTH: usize = 1280;
const NOISE_HEIGHT: usize = 720;

pub fn noise_open(texture_ptr: usize) -> usize {
    // Initialize noise and push noise frames to Flutter texture
    let renderer_main = FlutterTexture::new(texture_ptr, NOISE_WIDTH, NOISE_HEIGHT);
    let join_handle = white_noise::start_and_get_handle(NOISE_WIDTH, NOISE_HEIGHT, move |raw_frame| {
        renderer_main.on_rgba(&raw_frame);
    });

    // Store handle
    let handle_id = NOISE_HANDLE_COUNT.fetch_add(1, Ordering::SeqCst);
    NOISE_HANDLES.insert(handle_id, join_handle);

    handle_id
}

pub fn noise_get_frame() -> RawImage {
    white_noise::generate_frame(&Rng::new(), NOISE_WIDTH, NOISE_HEIGHT)
}

pub fn noise_close(handle_id: usize) {
    // Retrieve handle
    let handle = NOISE_HANDLES.remove(&handle_id).expect("Invalid noise handle ID");

    log_debug("Stopping white noise generator with handle ".to_string() + &handle_id.to_string());
    handle.1.stop();
    log_debug("Stopped white noise generator with handle ".to_string() + &handle_id.to_string());
}
