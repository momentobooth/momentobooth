use std::path::Path;

use flutter_rust_bridge::ZeroCopyBuffer;
use img_parts::{jpeg::Jpeg, Bytes, ImageEXIF};
use jpeg_encoder::{Encoder, ColorType};
use little_exif::{exif_tag::{ExifTag, ExifTagGroup}, filetype::FileExtension, metadata::Metadata};
use num::FromPrimitive;
use num_derive::FromPrimitive;
use zune_jpeg::{JpegDecoder, zune_core::{options::DecoderOptions, colorspace::ColorSpace}};
use chrono::{DateTime, Local, NaiveDateTime, TimeZone};

use crate::dart_bridge::api::RawImage;

pub fn encode_raw_to_jpeg(raw_image: RawImage, quality: u8, exif_tags: Vec<MomentoBoothExifTag>) -> ZeroCopyBuffer<Vec<u8>> {
    let mut output_buf: Vec<u8> = Vec::new();
    let encoder = Encoder::new(&mut output_buf, quality);

    encoder.encode(&raw_image.data, raw_image.width as u16, raw_image.height as u16, ColorType::Rgba).expect("Error while encoding to JPEG");

    // Create EXIF metadata
    let mut metadata = Metadata::new();
    for tag in exif_tags {
        metadata.set_tag(tag.into());
    }
    let metadata_vec = metadata.as_u8_vec(FileExtension::JPEG);

    // Write EXIF metadata to the JPEG in memory
    let mut jpeg = Jpeg::from_bytes(Bytes::copy_from_slice(&output_buf)).expect("Error while reading JPEG data");
    jpeg.set_exif(Some(Bytes::copy_from_slice(&metadata_vec[10..])));

    ZeroCopyBuffer(jpeg.encoder().bytes().to_vec())
}

lazy_static::lazy_static! {
    static ref JPEG_TO_RGBA_DECODER_OPTIONS: DecoderOptions = DecoderOptions::new_fast().jpeg_set_out_colorspace(ColorSpace::RGBA);
}

pub fn decode_jpeg_to_rgba(jpeg_data: &[u8]) -> RawImage {
    let mut decoder = JpegDecoder::new_with_options(jpeg_data, *JPEG_TO_RGBA_DECODER_OPTIONS);
    let pixels = decoder.decode().expect("Could not decode JPEG data");
    let image_info = decoder.info().expect("Could not extract JPEG info");

    RawImage::new_from_rgba_data(
        pixels,
        image_info.width as usize,
        image_info.height as usize,
    )
}

// //// //
// EXIF //
// //// //

pub fn get_momento_booth_exif_tags_from_file(image_file_path: &str) -> Vec<MomentoBoothExifTag> {
    let image_path = Path::new(image_file_path);
    let metadata = Metadata::new_from_path(&image_path).unwrap();

    let mut exif_tags: Vec<MomentoBoothExifTag> = Vec::new();
    for tag in metadata.data() {
        match MomentoBoothExifTag::try_from(tag) {
            Ok(tag) => exif_tags.push(tag),
            Err(_) => (),
        }
    };

    exif_tags
}

impl From<MomentoBoothExifTag> for ExifTag {
    fn from(tag: MomentoBoothExifTag) -> ExifTag {
        match tag {
            MomentoBoothExifTag::ImageDescription(value) => ExifTag::ImageDescription(value),
            MomentoBoothExifTag::Software(value) => ExifTag::Software(value),
            MomentoBoothExifTag::CreateDate(value) => ExifTag::CreateDate(value.to_utc().format("%Y:%m:%d %H:%M:%S").to_string()),
            MomentoBoothExifTag::Orientation(value) => ExifTag::Orientation(vec!(value as u16)),
            MomentoBoothExifTag::ImageHistory(value) => ExifTag::UnknownSTRING(value, 0x9213, ExifTagGroup::IFD0),
            MomentoBoothExifTag::MakerNote(value) => ExifTag::UnknownSTRING(value, 0x927C, ExifTagGroup::ExifIFD),
        }
    }
}

impl TryFrom<&ExifTag> for MomentoBoothExifTag {
    type Error = &'static str;

    fn try_from(exif_tag: &ExifTag) -> Result<MomentoBoothExifTag, Self::Error> {
        match exif_tag {
            ExifTag::ImageDescription(value) => Ok(MomentoBoothExifTag::ImageDescription(value.clone())),
            ExifTag::Software(value) => Ok(MomentoBoothExifTag::Software(value.clone())),
            ExifTag::CreateDate(value) => {
                let fixed_offset_date = DateTime::parse_from_str(&value, "%Y:%m:%d %H:%M:%S").expect("Error while parsing EXIF create date");
                let local_date = DateTime::from_timestamp(fixed_offset_date.timestamp(), 0).unwrap().with_timezone(&Local);
                Ok(MomentoBoothExifTag::CreateDate(local_date))
            },
            ExifTag::Orientation(value) => {
                let orientation: Option<ExifOrientation> = ExifOrientation::from_u16(value[0]);
                match orientation {
                    Some(orientation) => Ok(MomentoBoothExifTag::Orientation(orientation)),
                    None => Err("Unknown orientation"),
                }
            },
            ExifTag::UnknownSTRING(value, tag_id, tag_group) => {
                match (tag_id, tag_group) {
                    (0x9213, ExifTagGroup::IFD0) => Ok(MomentoBoothExifTag::ImageHistory(value.clone())),
                    (0x927C, ExifTagGroup::ExifIFD) => Ok(MomentoBoothExifTag::MakerNote(value.clone())),
                    _ => Err("Unknown tag"),
                }
            },
            _ => Err("Unknown tag"),
        }
    }
}

pub enum MomentoBoothExifTag {
    ImageDescription(String),
    Software(String),
    CreateDate(DateTime<Local>),
    Orientation(ExifOrientation),
    ImageHistory(String),
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
