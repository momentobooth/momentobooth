
pub use ipp::model::PrinterState;
pub use ipp::model::JobState;
use flutter_rust_bridge::frb;

use url::Url;

use crate::utils::ipp_client::{self, IppPrinterState, PrintJobState};

fn cups_build_url(printer_id: String) -> String {
    let base = Url::parse("http://photobooth:photobooth@localhost:631/printers/").unwrap();
    base.join(&printer_id).unwrap().to_string()
}

pub fn cups_get_printer_state(printer_id: String) -> IppPrinterState {
    let uri = cups_build_url(printer_id);
    ipp_client::get_printer_state(uri)
}

pub fn cups_resume_printer(printer_id: String) {
    let uri = cups_build_url(printer_id);
    ipp_client::resume_printer(uri);
}

pub fn cups_get_jobs_states(printer_id: String) -> Vec<PrintJobState> {
    let uri = cups_build_url(printer_id);
    ipp_client::get_jobs_states(uri)
}

// ////////////// //
// Mirror structs //
// ////////////// //

#[frb(mirror(PrinterState))]
pub enum _PrinterState {
    Idle = 3,
    Processing = 4,
    Stopped = 5,
}

#[frb(mirror(JobState))]
pub enum _JobState {
    Pending = 3,
    PendingHeld = 4,
    Processing = 5,
    ProcessingStopped = 6,
    Canceled = 7,
    Aborted = 8,
    Completed = 9,
}
