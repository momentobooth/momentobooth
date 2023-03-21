use nokhwa::{utils::{CameraIndex, RequestedFormat, RequestedFormatType, CameraInfo}, pixel_format::RgbFormat, Camera, query, native_api_backend};

pub fn get_webcams() -> Vec<NokhwaCameraInfo> {
    let backend = native_api_backend().unwrap();
    let devices = query(backend).unwrap();

    let device_names: Vec<NokhwaCameraInfo> = devices.iter().map(|d| NokhwaCameraInfo::from_camera_info(d)).collect();
    return device_names;
}

pub struct NokhwaCameraInfo {
    id: CameraIndex,
    pub friendly_name: String,
}

impl NokhwaCameraInfo {
    pub fn from_camera_info(camera_info: &CameraInfo) -> Self {
        Self { id: camera_info.index().clone(), friendly_name: camera_info.human_name() }
    }
}
