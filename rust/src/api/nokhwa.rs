use crate::{hardware_control::live_view::nokhwa::{self, NokhwaCameraInfo}, models::{images::RawImage, live_view::CameraState}, utils::image_processing::ImageOperation};

pub async fn nokhwa_initialize() -> bool {
    nokhwa::initialize_nokhwa().await
}

pub fn nokhwa_get_cameras() -> Vec<NokhwaCameraInfo> {
    nokhwa::nokhwa_get_cameras()
}

pub fn nokhwa_open_camera(friendly_name: String, operations: Vec<ImageOperation>, texture_ptr: usize) -> u32 {
    nokhwa::nokhwa_open_camera(friendly_name, operations, texture_ptr)
}

pub fn nokhwa_set_operations(handle_id: u32, operations: Vec<ImageOperation>) {
    nokhwa::nokhwa_set_operations(handle_id, operations)
}

pub fn nokhwa_get_camera_status(handle_id: u32) -> CameraState {
    nokhwa::nokhwa_get_camera_status(handle_id)
}

pub fn nokhwa_get_last_frame(handle_id: u32) -> Option<RawImage> {
    nokhwa::nokhwa_get_last_frame(handle_id)
}

pub fn nokhwa_close_camera(handle_id: u32) {
    nokhwa::nokhwa_close_camera(handle_id)
}
