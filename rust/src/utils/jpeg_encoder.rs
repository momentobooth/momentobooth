use flutter_rust_bridge::ZeroCopyBuffer;
use jpeg_encoder::{Encoder, ColorType};

use super::image_processing::RawImage;

pub fn encode_rgba(raw_image: RawImage, quality: u8) -> ZeroCopyBuffer<Vec<u8>> {
    let mut output_buf: Vec<u8> = Vec::new();
    let encoder = Encoder::new(&mut output_buf, quality);

    // Encode the data with dimension 2x2
    encoder.encode(&raw_image.raw_rgba_data, raw_image.width as u16, raw_image.height as u16, ColorType::Rgba).expect("Error while encoding to JPEG");

    ZeroCopyBuffer(output_buf)
}
