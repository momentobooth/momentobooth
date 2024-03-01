use flutter_rust_bridge::ZeroCopyBuffer;
use img_parts::{jpeg::Jpeg, Bytes, ImageEXIF};
use jpeg_encoder::{Encoder, ColorType};
use little_exif::{exif_tag::{ExifTag, ExifTagGroup}, filetype::FileExtension, metadata::Metadata};
use zune_jpeg::{JpegDecoder, zune_core::{options::DecoderOptions, colorspace::ColorSpace}};
use chrono::{DateTime, Local};

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

pub enum MomentoBoothExifTag {
    ImageDescription(String),
    Software(String),
    CreateDate(DateTime<Local>),
    Orientation(ExifOrientation),
    ImageHistory(String),
}

impl From<MomentoBoothExifTag> for ExifTag {
    fn from(tag: MomentoBoothExifTag) -> ExifTag {
        match tag {
            MomentoBoothExifTag::ImageDescription(value) => ExifTag::ImageDescription(value),
            MomentoBoothExifTag::Software(value) => ExifTag::Software(value),
            MomentoBoothExifTag::CreateDate(value) => ExifTag::CreateDate(value.to_utc().format("%Y:%m:%d %H:%M:%S").to_string()),
            MomentoBoothExifTag::Orientation(value) => ExifTag::Orientation(vec!(value as u16)),
            MomentoBoothExifTag::ImageHistory(value) => ExifTag::UnknownSTRING(value.to_string(), 0x9213, ExifTagGroup::IFD0),
        }
    }
}

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
