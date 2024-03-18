use chrono::Duration;

pub struct CameraState {
    pub is_streaming: bool,
    pub valid_frame_count: usize,
    pub error_frame_count: usize,
    pub duplicate_frame_count: usize,
    pub last_frame_was_valid: bool,
    pub time_since_last_received_frame: Option<Duration>,
    pub frame_width: Option<usize>,
    pub frame_height: Option<usize>,
}
