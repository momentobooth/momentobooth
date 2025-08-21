use escpos::{driver::NativeUsbDriver, printer::Printer, printer_options::PrinterOptions, utils::Protocol};
use image::{imageops, GrayImage, Luma};
use snafu::{ResultExt, Snafu};
use crate::models::receipt_printing::{Receipt, ReceiptPrinterCommand};

// ////////////////////// //
// Main printing function //
// ////////////////////// //

pub fn print(receipt: Receipt, usb_vid: u16, usb_pid: u16, print_width: u16) -> Result<(), PrintingError> {
    let driver = NativeUsbDriver::open(usb_vid, usb_pid).context(PrinterOpenFailedSnafu {})?;
    let mut binding = Printer::new(driver, Protocol::default(), Some(PrinterOptions::default()));
    let printer = binding.init().context(PrinterInitFailedSnafu {})?;

    for command in receipt.commands {
        match command {
            ReceiptPrinterCommand::PrintImage(items) => {
                let escpos_image = image_to_escpos_bitimage_bytes(&items, print_width)?;
                printer.custom(&escpos_image).context(PrintImageFailedSnafu {})?;
            },
            ReceiptPrinterCommand::PrintText(text) => {
                printer.writeln(&text).context(PrintTextFailedSnafu {})?;
            },
            ReceiptPrinterCommand::Cut => {
                printer.cut().context(CutCommandFailedSnafu {})?;
            },
            ReceiptPrinterCommand::Feed => {
                printer.feed().context(FeedCommandFailedSnafu {})?;
            },
        }
    };

    printer.print().context(PrintingFailedSnafu {})?;
    Ok(())
}

// /////// //
// Helpers //
// /////// //

/// Convert image to ESC * 33 format with given width, padding and dithering.
fn image_to_escpos_bitimage_bytes(image_data: &[u8], width: u16) -> Result<Vec<u8>, PrintingError> {
    // Load and scale the image to the given width, but keep aspect ratio.
    let original = image::load_from_memory(image_data).context(ImageOpenFailedSnafu {})?;
    let resized = original.resize(width as u32, u32::MAX, imageops::FilterType::Lanczos3);
    let mut grayscale = resized.to_luma8();

    // Dither to bw using Floyd–Steinberg.
    let dithered = floyd_steinberg_dither(&mut grayscale);

    // Round height up to a multiple of 24.
    let (width, height) = dithered.dimensions();
    let padded_height = ((height + 23) / 24) * 24;
    let mut padded = GrayImage::from_pixel(width, padded_height, Luma([255]));
    imageops::overlay(&mut padded, &dithered, 0, 0);

    // Generate ESC/POS bytes.
    let mut out = Vec::new();
    let bytes_per_col = 3;

    for y in (0..padded_height).step_by(24) {
        out.extend_from_slice(&[
            0x1B, 0x2A, 33, // ESC * 33 = 24-dot double density
            (width & 0xFF) as u8,
            (width >> 8) as u8,
        ]);

        for x in 0..width {
            for byte in 0..bytes_per_col {
                let mut b = 0u8;
                for bit in 0..8 {
                    let py = y + (byte * 8 + bit);
                    if py >= padded_height {
                        continue;
                    }
                    let pixel = padded.get_pixel(x, py)[0];
                    let bit_val = if pixel < 128 { 1 } else { 0 };
                    b |= bit_val << (7 - bit);
                }
                out.push(b);
            }
        }

        out.push(0x0A); // LF
    }

    Ok(out)
}

fn floyd_steinberg_dither(image: &mut GrayImage) -> GrayImage {
    let (width, height) = image.dimensions();
    let mut result = image.clone();

    for y in 0..height {
        for x in 0..width {
            let old_pixel = result.get_pixel(x, y)[0] as i16;
            let new_pixel = if old_pixel < 128 { 0 } else { 255 };
            let error = old_pixel - new_pixel;

            result.put_pixel(x, y, Luma([new_pixel as u8]));

            // Spread dither.
            let mut distribute = |dx: i32, dy: i32, factor: f32| {
                let nx = x as i32 + dx;
                let ny = y as i32 + dy;
                if nx >= 0 && nx < width as i32 && ny >= 0 && ny < height as i32 {
                    let orig = result.get_pixel(nx as u32, ny as u32)[0] as i16;
                    let new = (orig + (error as f32 * factor).round() as i16).clamp(0, 255);
                    result.put_pixel(nx as u32, ny as u32, Luma([new as u8]));
                }
            };

            distribute(1, 0, 7.0 / 16.0);
            distribute(-1, 1, 3.0 / 16.0);
            distribute(0, 1, 5.0 / 16.0);
            distribute(1, 1, 1.0 / 16.0);
        }
    }

    result
}

// ////// //
// Errors //
// ////// //

#[derive(Debug, Snafu)]
#[snafu(visibility(pub(crate)))]
pub enum PrintingError {
    #[snafu(display("Could not load image"))]
    ImageOpenFailed { source: image::ImageError },

    #[snafu(display("Could not initialize printer"))]
    PrinterOpenFailed { source: escpos::errors::PrinterError },

    #[snafu(display("Could not initialize printer"))]
    PrinterInitFailed { source: escpos::errors::PrinterError },

    #[snafu(display("Could not print text"))]
    PrintTextFailed { source: escpos::errors::PrinterError },

    #[snafu(display("Could not print image"))]
    PrintImageFailed { source: escpos::errors::PrinterError },

    #[snafu(display("Cut command failed"))]
    CutCommandFailed { source: escpos::errors::PrinterError },

    #[snafu(display("Feed command failed"))]
    FeedCommandFailed { source: escpos::errors::PrinterError },

    #[snafu(display("Actual printing with full data failed"))]
    PrintingFailed { source: escpos::errors::PrinterError },
}
