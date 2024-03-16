use std::fs::File;

use flutter_rust_bridge::ZeroCopyBuffer;
use img_parts::{jpeg::Jpeg, Bytes, ImageEXIF};
use jpeg_encoder::{Encoder, ColorType};
use little_exif::{exif_tag::ExifTagGroup, filetype::FileExtension, metadata::Metadata};
use num::FromPrimitive;
use num_derive::FromPrimitive;
use zune_jpeg::{JpegDecoder, zune_core::{options::DecoderOptions, colorspace::ColorSpace}};
use chrono::{DateTime, Local};
use nom_exif::ExifTag::{*};

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

// Note about implementation:
// This currently uses two different libraries for reading and writing EXIF data.

// This is because the `little-exif` library is used for creating the EXIF data (in combination with img_parts for adding it to the JPEG data),
// however `little-exif` does not correctly read the EXIF data back as of version 0.3.1.

// The `nom-exif` library is used for reading the EXIF data, but it does not support writing EXIF data.
// Once `little-exif` supports reading EXIF data, the `nom-exif` library can be removed.

const TAGS: &[nom_exif::ExifTag] = &[
    Orientation,
    CreateDate,
    ImageDescription,
    Software,
    MakerNote,
];

pub fn get_momento_booth_exif_tags_from_file(image_file_path: &str) -> Vec<MomentoBoothExifTag> {
    let mut reader = File::open(image_file_path).unwrap();
    let exif = nom_exif::parse_jpeg_exif(&mut reader).unwrap();

    let exif_tags = exif.unwrap().get_values(TAGS);

    exif_tags.iter().map(|(tag, value)| {
        match tag {
            nom_exif::ExifTag::ImageDescription => MomentoBoothExifTag::ImageDescription(match value {
                nom_exif::EntryValue::Text(value) => value.clone(),
                _ => panic!("Invalid value type for ImageDescription"),
            }),
            nom_exif::ExifTag::Software => MomentoBoothExifTag::Software(match value {
                nom_exif::EntryValue::Text(value) => value.clone(),
                _ => panic!("Invalid value type for Software"),
            }),
            nom_exif::ExifTag::CreateDate => MomentoBoothExifTag::CreateDate(match value {
                nom_exif::EntryValue::Time(value) => value.with_timezone(&Local).clone(),
                _ => panic!("Invalid value type for CreateDate"),
            }),
            nom_exif::ExifTag::Orientation => MomentoBoothExifTag::Orientation(match value {
                nom_exif::EntryValue::U16(value) => ExifOrientation::from_u16(value.clone()).unwrap(),
                _ => panic!("Invalid value type for Orientation"),
            }),
            nom_exif::ExifTag::MakerNote => MomentoBoothExifTag::MakerNote(match value {
                nom_exif::EntryValue::Text(value) => value.clone(),
                _ => panic!("Invalid value type for MakerNote"),
            }),
            _ => panic!("Unknown tag"),
        }
    }).collect()
}

impl From<MomentoBoothExifTag> for little_exif::exif_tag::ExifTag {
    fn from(tag: MomentoBoothExifTag) -> little_exif::exif_tag::ExifTag {
        match tag {
            MomentoBoothExifTag::ImageDescription(value) => little_exif::exif_tag::ExifTag::ImageDescription(value),
            MomentoBoothExifTag::Software(value) => little_exif::exif_tag::ExifTag::Software(value),
            MomentoBoothExifTag::CreateDate(value) => little_exif::exif_tag::ExifTag::CreateDate(value.format("%Y:%m:%d %H:%M:%S").to_string()),
            MomentoBoothExifTag::Orientation(value) => little_exif::exif_tag::ExifTag::Orientation(vec!(value as u16)),
            MomentoBoothExifTag::MakerNote(value) => little_exif::exif_tag::ExifTag::UnknownSTRING(value, 0x927C, ExifTagGroup::ExifIFD),
        }
    }
}

// This is for future purpose when `little-exif` correctly supports reading EXIF data.
impl TryFrom<&little_exif::exif_tag::ExifTag> for MomentoBoothExifTag {
    type Error = &'static str;

    fn try_from(exif_tag: &little_exif::exif_tag::ExifTag) -> Result<MomentoBoothExifTag, Self::Error> {
        match exif_tag {
            little_exif::exif_tag::ExifTag::ImageDescription(value) => Ok(MomentoBoothExifTag::ImageDescription(value.clone())),
            little_exif::exif_tag::ExifTag::Software(value) => Ok(MomentoBoothExifTag::Software(value.clone())),
            little_exif::exif_tag::ExifTag::CreateDate(value) => {
                let fixed_offset_date = DateTime::parse_from_str(&value, "%Y:%m:%d %H:%M:%S").expect("Error while parsing EXIF create date");
                let local_date = DateTime::from_timestamp(fixed_offset_date.timestamp(), 0).unwrap().with_timezone(&Local);
                Ok(MomentoBoothExifTag::CreateDate(local_date))
            },
            little_exif::exif_tag::ExifTag::Orientation(value) => {
                let orientation: Option<ExifOrientation> = ExifOrientation::from_u16(value[0]);
                match orientation {
                    Some(orientation) => Ok(MomentoBoothExifTag::Orientation(orientation)),
                    None => Err("Unknown orientation"),
                }
            },
            little_exif::exif_tag::ExifTag::UnknownSTRING(value, tag_id, tag_group) => {
                match (tag_id, tag_group) {
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
