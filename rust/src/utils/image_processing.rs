use image::{imageops::{self, FilterType}, RgbaImage, ImageBuffer};

use crate::models::images::RawImage;

// /////////////////////////// //
// Structs and Main Operations //
// /////////////////////////// //

#[derive(Clone, Copy)]
pub enum ImageOperation {
    CropToAspectRatio(f64),
    Rotate(Rotation),
    Flip(FlipAxis),
    Resize(u32, u32),
}

#[derive(Clone, Copy)]
pub enum Rotation {
    Rotate90,
    Rotate180,
    Rotate270,
}

#[derive(Clone, Copy)]
pub enum FlipAxis {
    Horizontally,
    Vertically,
}

pub fn execute_operations(image: &RawImage, operations: &Vec<ImageOperation>) -> RawImage {
    let mut img_buf: ImageBuffer<image::Rgba<u8>, Vec<u8>> = RgbaImage::from_vec(image.width as u32, image.height as u32, image.data.clone()).expect("Could not create ImageBuffer from raw source image");

    for op in operations {
        img_buf = match op {
            ImageOperation::CropToAspectRatio(aspect_ratio) => crop_to_aspect_ratio(&mut img_buf, *aspect_ratio),
            ImageOperation::Rotate(rotation) => rotate(&img_buf, *rotation),
            ImageOperation::Flip(axis) => flip(&img_buf, *axis),
            ImageOperation::Resize(width, height) => resize(&img_buf, *width, *height),
        }
    }

    let width = img_buf.width() as usize;
    let height = img_buf.height() as usize;
    let output_buf = image::ImageBuffer::into_vec(img_buf);
    RawImage::new_from_rgba_data(output_buf, width, height)
}

// ///////////////////// //
// Individual operations //
// ///////////////////// //

fn crop_to_aspect_ratio(src_raw_image: &mut ImageBuffer<image::Rgba<u8>, Vec<u8>>, aspect_ratio: f64) -> ImageBuffer<image::Rgba<u8>, Vec<u8>> {
    // Determine dst image dimensions
    let src_aspect_ratio = src_raw_image.width() as f64 / src_raw_image.height() as f64;
    let dst_width: u32;
    let dst_height: u32;

    if src_aspect_ratio > aspect_ratio {
        // Cut left and right sides
        dst_width = (src_raw_image.height() as f64 * aspect_ratio).round() as u32;
        dst_height = src_raw_image.height() as u32;
    } else {
        // Cut top and bottom sides
        dst_width = src_raw_image.width() as u32;
        dst_height = (src_raw_image.width() as f64 / aspect_ratio).round() as u32;
    }

    let x = ((src_raw_image.width() - dst_width) as f64 / 2f64).round() as u32;
    let y = ((src_raw_image.height() - dst_height) as f64 / 2f64).round() as u32;

    // Crop image
    imageops::crop(src_raw_image, x as u32, y as u32, dst_width as u32, dst_height as u32).to_image()
}

fn rotate(src_raw_image: &ImageBuffer<image::Rgba<u8>, Vec<u8>>, rotation: Rotation) -> ImageBuffer<image::Rgba<u8>, Vec<u8>> {
    match rotation {
        Rotation::Rotate90 => imageops::rotate90(src_raw_image),
        Rotation::Rotate180 => imageops::rotate180(src_raw_image),
        Rotation::Rotate270 => imageops::rotate270(src_raw_image),
    }
}

fn flip(src_raw_image: &ImageBuffer<image::Rgba<u8>, Vec<u8>>, flip: FlipAxis) -> ImageBuffer<image::Rgba<u8>, Vec<u8>> {
    match flip {
        FlipAxis::Horizontally => imageops::flip_horizontal(src_raw_image),
        FlipAxis::Vertically => imageops::flip_vertical(src_raw_image),
    }
}

// Can potentially be made even faster using https://crates.io/crates/fast_image_resize
fn resize(src_raw_image: &ImageBuffer<image::Rgba<u8>, Vec<u8>>, width: u32, height: u32) -> ImageBuffer<image::Rgba<u8>, Vec<u8>> {
    imageops::resize(src_raw_image, width, height, FilterType::Triangle)
}
