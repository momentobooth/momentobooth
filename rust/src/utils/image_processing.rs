use image::{imageops::{self, FilterType}, RgbaImage};

use crate::dart_bridge::api::RawImage;

// /////////////////////////// //
// Structs and Main Operations //
// /////////////////////////// //

#[derive(Clone, Copy)]
pub enum ImageOperation {
    CropToAspectRatio(f64),
    Rotate(Rotation),
    Flip(FlipAxis),
    BackgroundBlur(f32),
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
    let mut current_image = image.clone();
    for op in operations {
        match op {
            ImageOperation::CropToAspectRatio(aspect_ratio) => current_image = crop_to_aspect_ratio(current_image, *aspect_ratio),
            ImageOperation::Rotate(rotation) => current_image = rotate(current_image, *rotation),
            ImageOperation::Flip(axis) => current_image = flip(current_image, *axis),
            ImageOperation::BackgroundBlur(sigma) => current_image = background_blur(current_image, *sigma),
        }
    }
    current_image
}

// ///////////////////// //
// Individual operations //
// ///////////////////// //

fn crop_to_aspect_ratio(src_raw_image: RawImage, aspect_ratio: f64) -> RawImage {
    // Determine dst image dimensions
    let src_aspect_ratio = src_raw_image.width as f64 / src_raw_image.height as f64;
    let dst_width;
    let dst_height;

    if src_aspect_ratio > aspect_ratio {
        // Cut left and right sides
        dst_width = (src_raw_image.height as f64 * aspect_ratio).round() as usize;
        dst_height = src_raw_image.height;
    } else {
        // Cut top and bottom sides
        dst_width = src_raw_image.width;
        dst_height = (src_raw_image.width as f64 / aspect_ratio).round() as usize;
    }

    let x = ((src_raw_image.width - dst_width) as f64 / 2f64).round() as usize;
    let y = ((src_raw_image.height - dst_height) as f64 / 2f64).round() as usize;

    // Crop image
    let mut src_img = RgbaImage::from_vec(src_raw_image.width as u32, src_raw_image.height as u32, src_raw_image.data).expect("Could not create ImageBuffer from raw source image");
    let dst_img = imageops::crop(&mut src_img, x as u32, y as u32, dst_width as u32, dst_height as u32).to_image();
    let dst_vec = image::ImageBuffer::into_vec(dst_img);

    // Return cropped image
    RawImage::new_from_rgba_data(dst_vec, dst_width, dst_height)
}

fn rotate(src_raw_image: RawImage, rotation: Rotation) -> RawImage {
    // Rotate image
    let src_img = RgbaImage::from_vec(src_raw_image.width as u32, src_raw_image.height as u32, src_raw_image.data).expect("Could not create ImageBuffer from raw source image");
    let result = match rotation {
        Rotation::Rotate90 => imageops::rotate90(&src_img),
        Rotation::Rotate180 => imageops::rotate180(&src_img),
        Rotation::Rotate270 => imageops::rotate270(&src_img),
    };

    // Return rotate image
    RawImage::new_from_rgba_data(result.to_vec(), result.width() as usize, result.height() as usize)
}

fn flip(src_raw_image: RawImage, flip: FlipAxis) -> RawImage {
    // Rotate image
    let src_img = RgbaImage::from_vec(src_raw_image.width as u32, src_raw_image.height as u32, src_raw_image.data).expect("Could not create ImageBuffer from raw source image");
    let result = match flip {
        FlipAxis::Horizontally => imageops::flip_horizontal(&src_img),
        FlipAxis::Vertically => imageops::flip_vertical(&src_img),
    };

    // Return flipped image
    RawImage::new_from_rgba_data(result.to_vec(), result.width() as usize, result.height() as usize)
}

fn background_blur(src_raw_image: RawImage, sigma: f32) -> RawImage {
    // Rotate image
    let src_img = RgbaImage::from_vec(src_raw_image.width as u32, src_raw_image.height as u32, src_raw_image.data).expect("Could not create ImageBuffer from raw source image");
    let result = imageops::resize(&src_img, 100, 75, FilterType::Triangle);

    // Return flipped image
    RawImage::new_from_rgba_data(result.to_vec(), result.width() as usize, result.height() as usize)
}
