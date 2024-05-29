use crate::{hardware_control::live_view::nokhwa::{self, NokhwaCameraInfo}, models::{images::RawImage, live_view::CameraState}, utils::image_processing::ImageOperation};

pub fn nokhwa_get_cameras() -> Vec<NokhwaCameraInfo> {
    nokhwa::get_cameras()
}

pub fn nokhwa_open_camera(friendly_name: String, operations: Vec<ImageOperation>, texture_ptr: usize) -> usize {
    nokhwa::nokhwa_open_camera(friendly_name, operations, texture_ptr)
}

pub fn nokhwa_set_operations(handle_id: usize, operations: Vec<ImageOperation>) {
    nokhwa::nokhwa_set_operations(handle_id, operations)
}

pub fn nokhwa_get_camera_status(handle_id: usize) -> CameraState {
    nokhwa::nokhwa_get_camera_status(handle_id)
}

pub fn nokhwa_get_last_frame(handle_id: usize) -> Option<RawImage> {
    nokhwa::nokhwa_get_last_frame(handle_id)
}

pub fn nokhwa_close_camera(handle_id: usize) {
    nokhwa::nokhwa_close_camera(handle_id)
}
