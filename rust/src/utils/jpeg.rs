use flutter_rust_bridge::ZeroCopyBuffer;
use jpeg_encoder::{Encoder, ColorType};
use zune_jpeg::JpegDecoder;

use crate::dart_bridge::api::RawImage;

pub fn encode_raw_to_jpeg(raw_image: RawImage, quality: u8) -> ZeroCopyBuffer<Vec<u8>> {
    let mut output_buf: Vec<u8> = Vec::new();
    let encoder = Encoder::new(&mut output_buf, quality);

    encoder.encode(&raw_image.data, raw_image.width as u16, raw_image.height as u16, ColorType::Rgba).expect("Error while encoding to JPEG");

    ZeroCopyBuffer(output_buf)
}

pub fn decode_jpeg_to_rgba(jpeg_data: Vec<u8>) -> RawImage {
    let mut decoder = JpegDecoder::new( & jpeg_data);
    let image_info = decoder.info().expect("Could not extract JPEG info");
    let pixels = decoder.decode().expect("Could not decode JPEG data");

    RawImage::new_from_rgba_data(
        pixels,
        image_info.width as usize,
        image_info.height as usize,
    )
}
