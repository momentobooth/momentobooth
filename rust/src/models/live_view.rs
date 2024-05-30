use chrono::Duration;

pub struct CameraState {
    pub is_streaming: bool,
    pub valid_frame_count: u32,
    pub error_frame_count: u32,
    pub duplicate_frame_count: u32,
    pub last_frame_was_valid: bool,
    pub time_since_last_received_frame: Option<Duration>,
    pub frame_width: Option<u32>,
    pub frame_height: Option<u32>,
}
