use chrono::{DateTime, Local};
use num_derive::FromPrimitive;

#[derive(Clone)]
pub struct RawImage {
    pub format: RawImageFormat,
    pub data: Vec<u8>,
    pub width: u32,
    pub height: u32,
}

impl RawImage {
    pub(crate) fn new_from_rgba_data(data: Vec<u8>, width: u32, height: u32) -> RawImage {
        Self {
            format: RawImageFormat::Rgba,
            data,
            width,
            height,
        }
    }
}

#[derive(Clone)]
pub enum RawImageFormat {
    Rgba,
}

pub enum MomentoBoothExifTag {
    ImageDescription(String),
    Software(String),
    CreateDate(DateTime<Local>),
    Orientation(ExifOrientation),
    MakerNote(String),
}

#[derive(FromPrimitive)]
pub enum ExifOrientation {
    TopLeft = 1,
    TopRight = 2,
    BottomRight = 3,
    BottomLeft = 4,
    LeftTop = 5,
    RightTop = 6,
    RightBottom = 7,
    LeftBottom = 8,
}
