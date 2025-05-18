use image::{imageops::{self, FilterType}, ImageBuffer, Rgb, RgbaImage};
use log::warn;
use thiserror::Error;

use crate::models::{image_operations::{FlipAxis, ImageOperation, Rotation}, images::RawImage};

// /////////////// //
// Main Operations //
// /////////////// //

pub fn execute_operations(image: &RawImage, operations: &Vec<ImageOperation>) -> RawImage {
    let mut img_buf: ImageBuffer<image::Rgba<u8>, Vec<u8>> = RgbaImage::from_vec(image.width as u32, image.height as u32, image.data.clone()).expect("Could not create ImageBuffer from raw source image");

    for op in operations {
        img_buf = match op {
            ImageOperation::CropContentRegion => crop_content_region(&mut img_buf),
            ImageOperation::CropToAspectRatio(aspect_ratio) => crop_to_aspect_ratio(&mut img_buf, *aspect_ratio),
            ImageOperation::Rotate(rotation) => rotate(&img_buf, *rotation),
            ImageOperation::Flip(axis) => flip(&img_buf, *axis),
            ImageOperation::Resize(width, height) => resize(&img_buf, *width, *height),
        }
    }

    let width = img_buf.width() as u32;
    let height = img_buf.height() as u32;
    let output_buf = image::ImageBuffer::into_vec(img_buf);
    RawImage::new_from_rgba_data(output_buf, width, height)
}

// ///////////////////// //
// Individual operations //
// ///////////////////// //

fn crop_content_region(src_raw_image: &mut ImageBuffer<image::Rgba<u8>, Vec<u8>>) -> ImageBuffer<image::Rgba<u8>, Vec<u8>> {
    match detect_borders(src_raw_image, Rgb([10, 10, 10])) {
        Ok(content_region) => {
            imageops::crop(src_raw_image, content_region.x as u32, content_region.y as u32, content_region.width as u32, content_region.y as u32).to_image()
        }
        Err(e) => {
            warn!("No valid content region detected, {:?}", e);
            src_raw_image.clone()
        }
    }
}

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

/// Represents a rectangular region within an image
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct ImageRegion {
    /// X-coordinate of the top-left corner
    pub x: u32,
    /// Y-coordinate of the top-left corner
    pub y: u32,
    /// Width of the region
    pub width: u32,
    /// Height of the region
    pub height: u32,
}

/// Errors that can occur during border detection
#[derive(Debug, Error)]
pub enum DetectBorderError {
    #[error("Image is completely black or borders cover the entire image")]
    AllBlack,
    #[error("No borders detected in the image")]
    NoBorders,
    #[error("Image dimensions are too small")]
    TooSmall,
}

/// Detects letterbox or pillarbox borders in an image and returns the content region
///
/// This function examines the middle row and column of pixels to determine where 
/// black borders end and actual content begins.
///
/// # Arguments
///
/// * `img` - The image to analyze
/// * `threshold` - RGB threshold value to consider a pixel as "black"
///
/// # Returns
///
/// * `Ok(ImageRegion)` - The region containing the actual image content
/// * `Err(DetectBorderError)` - If borders couldn't be detected properly
pub fn detect_borders<P, C>(img: &ImageBuffer<P, C>, threshold: Rgb<u8>) -> Result<ImageRegion, DetectBorderError>
where
    P: image::Pixel<Subpixel = u8> + 'static,
    C: std::ops::Deref<Target = [P::Subpixel]>,
{
    let width = img.width();
    let height = img.height();

    // Check if image is too small to analyze
    if width < 3 || height < 3 {
        return Err(DetectBorderError::TooSmall);
    }

    // Get the middle horizontal and vertical lines for analysis
    let mid_y = height / 2;
    let mid_x = width / 2;

    // Find borders in horizontal direction (letterbox detection)
    let mut left = 0;
    let mut right = width - 1;
    
    // Scan from left
    for x in 0..width {
        if !is_pixel_black(img.get_pixel(x, mid_y), threshold) {
            left = x;
            break;
        }
    }
    
    // Scan from right
    for x in (0..width).rev() {
        if !is_pixel_black(img.get_pixel(x, mid_y), threshold) {
            right = x;
            break;
        }
    }

    // Find borders in vertical direction (pillarbox detection)
    let mut top = 0;
    let mut bottom = height - 1;
    
    // Scan from top
    for y in 0..height {
        if !is_pixel_black(img.get_pixel(mid_x, y), threshold) {
            top = y;
            break;
        }
    }
    
    // Scan from bottom
    for y in (0..height).rev() {
        if !is_pixel_black(img.get_pixel(mid_x, y), threshold) {
            bottom = y;
            break;
        }
    }

    // Check if any content was found
    if left >= right || top >= bottom {
        return Err(DetectBorderError::AllBlack);
    }

    // If borders are unchanged from initial values, no borders were detected
    if left == 0 && right == width - 1 && top == 0 && bottom == height - 1 {
        return Err(DetectBorderError::NoBorders);
    }

    // Calculate the actual region dimensions
    let content_width = right - left + 1;
    let content_height = bottom - top + 1;

    Ok(ImageRegion {
        x: left,
        y: top,
        width: content_width,
        height: content_height,
    })
}

/// Determines if a pixel is black based on the threshold
fn is_pixel_black<P>(pixel: &P, threshold: Rgb<u8>) -> bool 
where
    P: image::Pixel<Subpixel = u8>,
{
    // For RGB and RGBA images, compare all channels
    if P::CHANNEL_COUNT >= 3 {
        let rgb = pixel.to_rgb();
        rgb[0] <= threshold[0] && rgb[1] <= threshold[1] && rgb[2] <= threshold[2]
    } else {
        // For grayscale images, compare only the first channel
        pixel.channels()[0] <= threshold[0]
    }
}
