use exif::{Tag, Value};
use img_parts::{jpeg::Jpeg, Bytes, ImageEXIF};
use jpeg_encoder::{Encoder, ColorType};
use little_exif::{exif_tag::ExifTagGroup, filetype::FileExtension, metadata::Metadata};
use num::FromPrimitive;
use zune_jpeg::{JpegDecoder, zune_core::{options::DecoderOptions, colorspace::ColorSpace}};
use chrono::NaiveDateTime;

use crate::models::images::{ExifOrientation, MomentoBoothExifTag, RawImage};

pub fn encode_raw_to_jpeg(raw_image: RawImage, quality: u8, exif_tags: Vec<MomentoBoothExifTag>) -> Vec<u8> {
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

    jpeg.encoder().bytes().to_vec()
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


pub fn get_momento_booth_exif_tags_from_file(image_file_path: &str) -> Vec<MomentoBoothExifTag> {
    let file = std::fs::File::open(image_file_path).unwrap();
    let mut bufreader = std::io::BufReader::new(&file);
    let exifreader = exif::Reader::new();
    let exif = exifreader.read_from_container(&mut bufreader).unwrap();

    exif.fields().map(|field| {
        match field.tag {
            Tag::ImageDescription => MomentoBoothExifTag::ImageDescription(match field.value {
                Value::Ascii(ref vec) if !vec.is_empty() => String::from_utf8(vec[0].clone()).unwrap(),
                _ => panic!("Invalid value type or empty value for ImageDescription"),
            }),
            Tag::Software => MomentoBoothExifTag::Software(match field.value {
                Value::Ascii(ref vec) if !vec.is_empty() => String::from_utf8(vec[0].clone()).unwrap(),
                _ => panic!("Invalid value type or empty value for Software"),
            }),
            Tag::DateTimeDigitized => MomentoBoothExifTag::CreateDate(match field.value {
                Value::Ascii(ref vec) if !vec.is_empty() => {
                    let date_time_str = String::from_utf8(vec[0].clone()).unwrap();
                    NaiveDateTime::parse_from_str(&date_time_str.to_string(), "%Y:%m:%d %H:%M:%S").unwrap().into()
                },
                _ => panic!("Invalid value type for CreateDate"),
            }),
            Tag::Orientation => MomentoBoothExifTag::Orientation(match field.value {
                Value::Short(ref value) => ExifOrientation::from_u16(value[0]).unwrap(),
                _ => panic!("Invalid value type for Orientation"),
            }),
            Tag::MakerNote => MomentoBoothExifTag::MakerNote(match field.value {
                Value::Undefined(ref data, _) => String::from_utf8(data.clone()).unwrap(),
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
            MomentoBoothExifTag::MakerNote(value) => little_exif::exif_tag::ExifTag::UnknownUNDEF(value.as_bytes().to_vec(), 0x927C, ExifTagGroup::ExifIFD),
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
                let fixed_offset_date = NaiveDateTime::parse_from_str(&value, "%Y:%m:%d %H:%M:%S").expect("Error while parsing EXIF create date");
                Ok(MomentoBoothExifTag::CreateDate(fixed_offset_date))
            },
            little_exif::exif_tag::ExifTag::Orientation(value) => {
                let orientation: Option<ExifOrientation> = ExifOrientation::from_u16(value[0]);
                match orientation {
                    Some(orientation) => Ok(MomentoBoothExifTag::Orientation(orientation)),
                    None => Err("Unknown orientation"),
                }
            },
            little_exif::exif_tag::ExifTag::UnknownUNDEF(value, tag_id, tag_group) => {
                match (tag_id, tag_group) {
                    (0x927C, ExifTagGroup::ExifIFD) => Ok(MomentoBoothExifTag::MakerNote(String::from_utf8(value.to_vec()).unwrap())),
                    _ => Err("Unknown tag"),
                }
            },
            _ => Err("Unknown tag"),
        }
    }
}


