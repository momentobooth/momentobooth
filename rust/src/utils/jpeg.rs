use flutter_rust_bridge::ZeroCopyBuffer;
use jpeg_encoder::{Encoder, ColorType};
use zune_jpeg::{JpegDecoder, zune_core::{options::DecoderOptions, colorspace::ColorSpace}};

use crate::dart_bridge::api::RawImage;

pub fn encode_raw_to_jpeg(raw_image: RawImage, quality: u8) -> ZeroCopyBuffer<Vec<u8>> {
    let mut output_buf: Vec<u8> = Vec::new();
    let encoder = Encoder::new(&mut output_buf, quality);

    encoder.encode(&raw_image.data, raw_image.width as u16, raw_image.height as u16, ColorType::Rgba).expect("Error while encoding to JPEG");

    ZeroCopyBuffer(output_buf)
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
