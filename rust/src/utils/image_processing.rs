use image::{imageops, RgbaImage};

// /////////////////////////// //
// Structs and Main Operations //
// /////////////////////////// //

pub struct RawImage {
    pub raw_rgba_data: Vec<u8>,
    pub width: usize,
    pub height: usize,
}

pub enum ImageOperation {
    CropToAspectRatio(f64),
}

pub fn execute_operations(image: RawImage, operations: &Vec<ImageOperation>) -> RawImage {
    let mut current_image = image;
    for op in operations {
        match op {
            ImageOperation::CropToAspectRatio(aspect_ratio) => current_image = crop_to_aspect_ratio(current_image, *aspect_ratio),
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
    let mut src_img = RgbaImage::from_vec(src_raw_image.width as u32, src_raw_image.height as u32, src_raw_image.raw_rgba_data).expect("Could not create ImageBuffer from raw source image");
    let dst_img = imageops::crop(&mut src_img, x as u32, y as u32, dst_width as u32, dst_height as u32).to_image();
    let dst_vec = image::ImageBuffer::into_vec(dst_img);

    // Return cropped image
    RawImage {
        raw_rgba_data: dst_vec,
        width: dst_width,
        height: dst_height,
    }
}
