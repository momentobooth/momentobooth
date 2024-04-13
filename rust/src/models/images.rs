use chrono::NaiveDateTime;
use num_derive::FromPrimitive;

#[derive(Clone)]
pub struct RawImage {
    pub format: RawImageFormat,
    pub data: Vec<u8>,
    pub width: usize,
    pub height: usize,
}

impl RawImage {
    pub(crate) fn new_from_rgba_data(data: Vec<u8>, width: usize, height: usize) -> RawImage {
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
    CreateDate(NaiveDateTime),
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
