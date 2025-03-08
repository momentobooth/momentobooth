use crate::{frb_generated::StreamSink, hardware_control::live_view::gphoto2::{self, GPhoto2CameraInfo, GPhoto2CameraSpecialHandling, GPhoto2File}, models::{images::RawImage, live_view::CameraState}, utils::image_processing::ImageOperation};

pub fn gphoto2_initialize(iolibs_path: String, camlibs_path: String) {
    gphoto2::gphoto2_initialize(iolibs_path, camlibs_path);
}

pub fn gphoto2_get_cameras() -> Vec<GPhoto2CameraInfo> {
    gphoto2::gphoto2_get_cameras()
}

pub fn gphoto2_open_camera(model: String, port: String, special_handling: GPhoto2CameraSpecialHandling) -> u32 {
    gphoto2::gphoto2_open_camera(model, port, special_handling)
}

pub fn gphoto2_close_camera(handle_id: u32) {
    gphoto2::gphoto2_close_camera(handle_id)
}

pub fn gphoto2_start_liveview(handle_id: u32, operations: Vec<ImageOperation>, texture_ptr: usize) {
    gphoto2::gphoto2_start_liveview(handle_id, operations, texture_ptr)
}

pub fn gphoto2_set_operations(handle_id: u32, operations: Vec<ImageOperation>) {
    gphoto2::gphoto2_set_operations(handle_id, operations)
}

pub fn gphoto2_stop_liveview(handle_id: u32) {
    gphoto2::gphoto2_stop_liveview(handle_id)
}

pub fn gphoto2_auto_focus(handle_id: u32) {
    gphoto2::gphoto2_auto_focus(handle_id)
}

pub fn gphoto2_clear_events(handle_id: u32, download_extra_files: bool) {
    gphoto2::gphoto2_clear_events(handle_id, download_extra_files)
}

pub fn gphoto2_capture_photo(handle_id: u32, capture_target_value: String) -> GPhoto2File {
    gphoto2::gphoto2_capture_photo(handle_id, capture_target_value)
}

pub fn gphoto2_get_camera_status(handle_id: u32) -> CameraState {
    gphoto2::gphoto2_get_camera_status(handle_id)
}

pub fn gphoto2_get_last_frame(handle_id: u32) -> Option<RawImage> {
    gphoto2::gphoto2_get_last_frame(handle_id)
}

pub fn gphoto2_set_extra_file_callback(handle_id: u32, image_sink: StreamSink<GPhoto2File>) {
    gphoto2::gphoto2_set_extra_file_callback(handle_id, image_sink)
}
