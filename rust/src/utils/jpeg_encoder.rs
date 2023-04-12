use flutter_rust_bridge::ZeroCopyBuffer;
use jpeg_encoder::{Encoder, ColorType};

pub fn encode_rgba(width: u16, height: u16, data: Vec<u8>, quality: u8) -> ZeroCopyBuffer<Vec<u8>> {
    let mut output_buf: Vec<u8> = Vec::new();
    let mut encoder = Encoder::new(output_buf, quality);

    // Encode the data with dimension 2x2
    encoder.encode(&data, width, height, ColorType::Rgba).expect("Error while encoding to JPEG");

    ZeroCopyBuffer(output_buf)
}
