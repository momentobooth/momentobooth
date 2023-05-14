use std::{thread::{self, JoinHandle}, time, sync::{atomic::{AtomicBool, Ordering}, Arc}};
use turborand::{rng::Rng, GenCore};

use crate::{dart_bridge::api::RawImage};

pub fn start_and_get_handle<F>(width: usize, height: usize, frame_callback: F) -> WhiteNoiseGeneratorHandle where F: Fn(RawImage) + Send + 'static {
    let ten_millis = time::Duration::from_millis(10);

    let should_stop = Arc::new(AtomicBool::new(false));
    let should_stop_clone = should_stop.clone();

    let join_handle = thread::spawn(move || {
        let rand = Rng::new();
        while !should_stop_clone.load(Ordering::SeqCst) {
            let mut noise = Vec::with_capacity(width*height*4);

            for _ in 0..width*height {
                let pixel_value: u8 = rand.gen_u8();
                noise.push(pixel_value);
                noise.push(pixel_value);
                noise.push(pixel_value);
                noise.push(255); // Opaque alpha channel
            }

            let frame = RawImage::new_from_rgba_data(noise, width, height);
            frame_callback(frame);

            thread::sleep(ten_millis)
        }
    });

    WhiteNoiseGeneratorHandle {
        thread_join_handle: join_handle,
        thread_should_stop: should_stop,
    }
}



pub struct WhiteNoiseGeneratorHandle {
    thread_join_handle: JoinHandle<()>,
    thread_should_stop: Arc<AtomicBool>,
}

impl WhiteNoiseGeneratorHandle {
    pub fn stop(self) {
        self.thread_should_stop.store(true, Ordering::SeqCst);
        self.thread_join_handle.join().expect("Could not join noise thread");
    }
}
