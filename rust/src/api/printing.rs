use crate::{hardware_control::printing::escpos, models::receipt_printing::Receipt};

pub fn print_receipt(receipt: Receipt, printer_usb_vid: u16, printer_usb_pid: u16, printing_width: u16) -> Result<(), escpos::PrintingError> {
    escpos::print(receipt, printer_usb_vid, printer_usb_pid, printing_width)
}
