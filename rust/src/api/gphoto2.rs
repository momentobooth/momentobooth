use crate::{frb_generated::StreamSink, hardware_control::live_view::gphoto2::{self, GPhoto2CameraInfo, GPhoto2CameraSpecialHandling, GPhoto2File}, models::{images::RawImage, live_view::CameraState}, utils::image_processing::ImageOperation};

pub fn gphoto2_get_cameras() -> Vec<GPhoto2CameraInfo> {
    gphoto2::gphoto2_get_cameras()
}

pub fn gphoto2_open_camera(model: String, port: String, special_handling: GPhoto2CameraSpecialHandling) -> usize {
    gphoto2::gphoto2_open_camera(model, port, special_handling)
}

pub fn gphoto2_close_camera(handle_id: usize) {
    gphoto2::gphoto2_close_camera(handle_id)
}

pub fn gphoto2_start_liveview(handle_id: usize, operations: Vec<ImageOperation>, texture_ptr: usize) {
    gphoto2::gphoto2_start_liveview(handle_id, operations, texture_ptr)
}

pub fn gphoto2_set_operations(handle_id: usize, operations: Vec<ImageOperation>) {
    gphoto2::gphoto2_set_operations(handle_id, operations)
}

pub fn gphoto2_stop_liveview(handle_id: usize) {
    gphoto2::gphoto2_stop_liveview(handle_id)
}

pub fn gphoto2_auto_focus(handle_id: usize) {
    gphoto2::gphoto2_auto_focus(handle_id)
}

pub fn gphoto2_clear_events(handle_id: usize, download_extra_files: bool) {
    gphoto2::gphoto2_clear_events(handle_id, download_extra_files)
}

pub fn gphoto2_capture_photo(handle_id: usize, capture_target_value: String) -> GPhoto2File {
    gphoto2::gphoto2_capture_photo(handle_id, capture_target_value)
}

pub fn gphoto2_get_camera_status(handle_id: usize) -> CameraState {
    gphoto2::gphoto2_get_camera_status(handle_id)
}

pub fn gphoto2_get_last_frame(handle_id: usize) -> Option<RawImage> {
    gphoto2::gphoto2_get_last_frame(handle_id)
}

pub fn gphoto2_set_extra_file_callback(handle_id: usize, image_sink: StreamSink<GPhoto2File>) {
    gphoto2::gphoto2_set_extra_file_callback(handle_id, image_sink)
}
