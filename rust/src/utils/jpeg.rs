use std::{io::Cursor, path::Path, sync::LazyLock};

use img_parts::{jpeg::Jpeg, Bytes, ImageEXIF};
use jpeg_encoder::{Encoder, ColorType};
use little_exif::{exif_tag::ExifTag, filetype::FileExtension, metadata::Metadata};
use num::FromPrimitive;
use zune_jpeg::{JpegDecoder, zune_core::{options::DecoderOptions, colorspace::ColorSpace}};
use chrono::{Local, NaiveDateTime};

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
    let metadata_vec = metadata.as_u8_vec(FileExtension::JPEG).unwrap();

    // Write EXIF metadata to the JPEG in memory
    let mut jpeg = Jpeg::from_bytes(Bytes::copy_from_slice(&output_buf)).expect("Error while reading JPEG data");
    jpeg.set_exif(Some(Bytes::copy_from_slice(&metadata_vec[10..])));

    jpeg.encoder().bytes().to_vec()
}

static JPEG_TO_RGBA_DECODER_OPTIONS: LazyLock<DecoderOptions> = LazyLock::new(|| DecoderOptions::new_fast().jpeg_set_out_colorspace(ColorSpace::RGBA));

pub fn decode_jpeg_to_rgba(jpeg_data: &[u8]) -> RawImage {
    let mut decoder = JpegDecoder::new_with_options(Cursor::new(jpeg_data), *JPEG_TO_RGBA_DECODER_OPTIONS);
    let pixels = decoder.decode().expect("Could not decode JPEG data");
    let image_info = decoder.info().expect("Could not extract JPEG info");

    RawImage::new_from_rgba_data(
        pixels,
        image_info.width as u32,
        image_info.height as u32,
    )
}

// //// //
// EXIF //
// //// //

pub fn get_momento_booth_exif_tags_from_file(image_file_path: &str) -> Vec<MomentoBoothExifTag> {
    let metadata = Metadata::new_from_path(Path::new(image_file_path)).unwrap();
    let mut tags: Vec<MomentoBoothExifTag> = Vec::new();

    if let Some(tag) = metadata.get_tag(&ExifTag::ImageDescription(String::new())).next() {
        tags.push(<MomentoBoothExifTag as TryFrom<&little_exif::exif_tag::ExifTag>>::try_from(tag).unwrap());
    }
    if let Some(tag) = metadata.get_tag(&ExifTag::Software(String::new())).next() {
        tags.push(<MomentoBoothExifTag as TryFrom<&little_exif::exif_tag::ExifTag>>::try_from(tag).unwrap());
    }
    if let Some(tag) = metadata.get_tag(&ExifTag::CreateDate(String::new())).next() {
        tags.push(<MomentoBoothExifTag as TryFrom<&little_exif::exif_tag::ExifTag>>::try_from(tag).unwrap());
    }
    if let Some(tag) = metadata.get_tag(&ExifTag::Orientation(Vec::<u16>::new())).next() {
        tags.push(<MomentoBoothExifTag as TryFrom<&little_exif::exif_tag::ExifTag>>::try_from(tag).unwrap());
    }
    if let Some(tag) = metadata.get_tag(&ExifTag::MakerNote(Vec::<u8>::new())).next() {
        tags.push(<MomentoBoothExifTag as TryFrom<&little_exif::exif_tag::ExifTag>>::try_from(tag).unwrap());
    }

    tags
}

impl From<MomentoBoothExifTag> for little_exif::exif_tag::ExifTag {
    fn from(tag: MomentoBoothExifTag) -> little_exif::exif_tag::ExifTag {
        match tag {
            MomentoBoothExifTag::ImageDescription(value) => little_exif::exif_tag::ExifTag::ImageDescription(value),
            MomentoBoothExifTag::Software(value) => little_exif::exif_tag::ExifTag::Software(value),
            MomentoBoothExifTag::CreateDate(value) => little_exif::exif_tag::ExifTag::CreateDate(value.format("%Y:%m:%d %H:%M:%S").to_string()),
            MomentoBoothExifTag::Orientation(value) => little_exif::exif_tag::ExifTag::Orientation(vec!(value as u16)),
            MomentoBoothExifTag::MakerNote(value) => little_exif::exif_tag::ExifTag::MakerNote(value.as_bytes().to_vec()),
        }
    }
}

impl TryFrom<&little_exif::exif_tag::ExifTag> for MomentoBoothExifTag {
    type Error = &'static str;

    fn try_from(exif_tag: &little_exif::exif_tag::ExifTag) -> Result<MomentoBoothExifTag, Self::Error> {
        match exif_tag {
            little_exif::exif_tag::ExifTag::ImageDescription(value) => Ok(MomentoBoothExifTag::ImageDescription(value.clone())),
            little_exif::exif_tag::ExifTag::Software(value) => Ok(MomentoBoothExifTag::Software(value.clone())),
            little_exif::exif_tag::ExifTag::CreateDate(value) => {
                let fixed_offset_date = NaiveDateTime::parse_from_str(&value, "%Y:%m:%d %H:%M:%S").expect("Error while parsing EXIF create date").and_local_timezone(Local).unwrap();
                Ok(MomentoBoothExifTag::CreateDate(fixed_offset_date))
            },
            little_exif::exif_tag::ExifTag::Orientation(value) => {
                let orientation: Option<ExifOrientation> = ExifOrientation::from_u16(value[0]);
                match orientation {
                    Some(orientation) => Ok(MomentoBoothExifTag::Orientation(orientation)),
                    None => Err("Unknown orientation"),
                }
            },
            little_exif::exif_tag::ExifTag::MakerNote(value) => Ok(MomentoBoothExifTag::MakerNote(String::from_utf8(value.to_vec()).unwrap())),
            _ => Err("Unknown tag"),
        }
    }
}
