use std::io::Cursor;
use futures::AsyncReadExt;
use chrono::{DateTime, Utc};

use ipp::attribute::IppAttrWithName;
use ipp::prelude::*;
use regex::Regex;
use futures::future::join_all;

/// Send an IPP request to do `op` to the given `uri` and get the response.
///
/// # Arguments
///
/// * `uri`: Printer or server URI
/// * `op`: Operation
///
/// returns: Result<IppRequestResponse, IppError>
///
/// # Examples
///
/// ```
/// send_ipp_request(uri, Operation::ResumePrinter).header().status_code().is_success()
/// ```
async fn send_ipp_request(uri: String, ignore_tls_errors: bool, op: Operation) -> IppRequestResponse {
    let uri_p: Uri = uri.parse().unwrap();
    let req = IppRequestResponse::new(
        IppVersion::v1_1(),
        op,
        Some(uri_p.clone())
    ).unwrap();
    let client = AsyncIppClient::builder(uri_p).ignore_tls_errors(ignore_tls_errors).build();
    let resp = client.send(req).await;
    resp.unwrap()
}

/// Send an IPP request to do `op` to job `job_id` to the given `uri` and get the response.
///
/// # Arguments
///
/// * `uri`: Printer or server URI
/// * `op`: Operation
/// * `job_id`: Job id
///
/// returns: Result<IppRequestResponse, IppError>
///
/// # Examples
///
/// ```
/// send_ipp_job_request(uri, Operation::RestartJob, job_id).header().status_code().is_success()
/// ```
async fn send_ipp_job_request(uri: String, ignore_tls_errors: bool, op: Operation, job_id: i32) -> IppRequestResponse {
    let uri_p: Uri = uri.parse().unwrap();
    let mut req = IppRequestResponse::new(
        IppVersion::v1_1(),
        op,
        Some(uri_p.clone())
    ).unwrap();
    req.attributes_mut().add(
        DelimiterTag::OperationAttributes,
        IppValue::new_integer(job_id).with_name(IppAttribute::JOB_ID).unwrap(),
    );

    let client = AsyncIppClient::builder(uri_p).ignore_tls_errors(ignore_tls_errors).build();
    let resp = client.send(req).await;
    resp.unwrap()
}

pub async fn resume_printer(uri: String, ignore_tls_errors: bool) -> bool {
    send_ipp_request(uri, ignore_tls_errors, Operation::ResumePrinter).await.header().status_code().is_success()
}

pub async fn purge_jobs(uri: String, ignore_tls_errors: bool) -> bool {
    send_ipp_request(uri, ignore_tls_errors, Operation::PurgeJobs).await.header().status_code().is_success()
}

pub async fn print_job(uri: String, ignore_tls_errors: bool, job_name: String, pdf_data: Vec<u8>, media_size: String) -> bool {
    let uri_p: Uri = uri.parse().unwrap();
    let pdf_data_cursor = Cursor::new(pdf_data);
    let pdf_data_payload = IppPayload::new(pdf_data_cursor);
    let print_job = IppOperationBuilder::print_job(uri_p.clone(), pdf_data_payload)
        .job_title(job_name)
        .attribute(IppValue::new_keyword(media_size).with_name("media").unwrap());

    let client = AsyncIppClient::builder(uri_p).ignore_tls_errors(ignore_tls_errors).build();
    let resp = client.send(print_job.build().unwrap()).await;
    resp.unwrap().header().status_code().is_success()
}

pub async fn restart_job(uri: String, ignore_tls_errors: bool, job_id: i32) -> bool {
    send_ipp_job_request(uri, ignore_tls_errors, Operation::RestartJob, job_id).await.header().status_code().is_success()
}

pub async fn release_job(uri: String, ignore_tls_errors: bool, job_id: i32) -> bool {
    send_ipp_job_request(uri, ignore_tls_errors, Operation::ReleaseJob, job_id).await.header().status_code().is_success()
}

pub async fn cancel_job(uri: String, ignore_tls_errors: bool, job_id: i32) -> bool {
    send_ipp_job_request(uri, ignore_tls_errors, Operation::CancelJob, job_id).await.header().status_code().is_success()
}

pub async fn get_printers(uri: String, ignore_tls_errors: bool) -> Vec<IppPrinterState> {
    let resp = send_ipp_request(uri.clone(), ignore_tls_errors, Operation::CupsGetPrinters).await;

    resp.attributes().groups_of(DelimiterTag::PrinterAttributes).map(|printer| {
        let state = printer.get("printer-state").unwrap()
            .value()
            .as_enum()
            .and_then(|v| PrinterState::from_i32(*v))
            .unwrap();
        let job_count = printer.get("queued-job-count").unwrap().value().as_integer().unwrap().clone();
        let state_message = printer.get("printer-state-message").unwrap().value().to_string().clone();
        let queue_name = printer.get("printer-name").unwrap().value().to_string().clone();
        let description = printer.get("printer-info").unwrap().value().to_string().clone();
        let state_reason = printer.get("printer-state-reasons").unwrap().value().to_string().clone();
        IppPrinterState { queue_name, description, state, job_count, state_message, state_reason }
    }).collect()
}

pub async fn get_printer_state(uri: String, ignore_tls_errors: bool) -> IppPrinterState {
    let resp = send_ipp_request(uri.clone(), ignore_tls_errors, Operation::GetPrinterAttributes).await;

    let group = resp.attributes().groups_of(DelimiterTag::PrinterAttributes).next().unwrap();
    let state = group.get("printer-state").unwrap()
        .value()
        .as_enum()
        .and_then(|v| PrinterState::from_i32(*v))
        .unwrap();
    let job_count = group.get("queued-job-count").unwrap().value().as_integer().unwrap().clone();
    let state_message = group.get("printer-state-message").unwrap().value().to_string().clone();
    let queue_name = group.get("printer-name").unwrap().value().to_string().clone();
    let description = group.get("printer-info").unwrap().value().to_string().clone();
    let state_reason = group.get("printer-state-reasons").unwrap().value().to_string().clone();

    IppPrinterState { queue_name, description, state, job_count, state_message, state_reason }
}

pub async fn get_jobs_states(uri: String, ignore_tls_errors: bool) -> Vec<PrintJobState> {
    let resp = send_ipp_request(uri.clone(), ignore_tls_errors, Operation::GetJobs).await;

    join_all(resp.attributes().groups_of(DelimiterTag::JobAttributes).map(|job| {
        let job_id = job.get("job-id").unwrap().value().as_integer().unwrap().clone();
        get_job_state(uri.clone(), ignore_tls_errors, job_id)
    })).await
}

async fn get_job_state(uri: String, ignore_tls_errors: bool, job_id: i32) -> PrintJobState {
    let resp = send_ipp_job_request(uri.clone(), ignore_tls_errors, Operation::GetJobAttributes, job_id).await;

    let group = resp.attributes().groups_of(DelimiterTag::JobAttributes).next().unwrap();
    let state = group.get("job-state").unwrap()
        .value()
        .as_enum()
        .and_then(|v| JobState::from_i32(*v))
        .unwrap();

    let creation_time = DateTime::from_timestamp_millis((group.get("time-at-creation").unwrap().value().as_integer().unwrap().clone() as i64) * 1000).unwrap();

    // Not every job seems to have a name
    let job_name = if let Some(name) = group.get("job-name") { name.value().to_string() } else { "".to_string() };

    PrintJobState {
        name: job_name,
        id: group.get("job-id").unwrap().value().as_integer().unwrap().clone(),
        state,
        reason: group.get("job-state-reasons").unwrap().value().to_string().clone(),
        created: creation_time,
    }
}

pub async fn get_printer_media_dimensions(uri: String, ignore_tls_errors: bool) -> Vec<PrintDimension> {
    let resp = send_ipp_request(uri, ignore_tls_errors, Operation::CupsGetPPD).await;
    let mut payload = resp.into_payload();
    let mut ppd = String::new();
    let _ = payload.read_to_string(&mut ppd).await;
    parse_paper_dimensions(&ppd)
}

/// Reads the page sizes from the `*PaperDimension` lines of a PPD, e.g. `*PaperDimension w288h432-div2/2x6*2: "307.680 442.560"`.
///
/// The keyword (`w288h432-div2`) is what a print job passes as `media`. It is taken from the PPD rather than from the `media-supported`
/// attribute of the printer, as CUPS lists page sizes with the same dimensions only once there, e.g. the cutting modes of a dye-sublimation
/// printer that all use 4x6 inch paper. Only the PPD keyword selects such a page size.
fn parse_paper_dimensions(ppd: &str) -> Vec<PrintDimension> {
    let re = Regex::new(r#"^\*PaperDimension\s+([^/:]+)(?:/([^:]+))?:\s*"(\d+(?:\.\d+)?)\s+(\d+(?:\.\d+)?)""#).unwrap();
    let points_per_mm = 72.0 / 25.4;

    ppd.lines().filter_map(|line| {
        let caps = re.captures(line)?;
        let keyword = caps[1].trim().to_string();
        let name = caps.get(2).map_or(keyword.clone(), |name| name.as_str().trim().to_string());
        let width = caps[3].parse::<f64>().ok()? / points_per_mm;
        let height = caps[4].parse::<f64>().ok()? / points_per_mm;
        Some(PrintDimension { name, height, width, keyword })
    }).collect()
}

// Use for debugging:
// fn print_attributes(attributes: HashMap<String, IppAttribute>) {
//     for attribute in attributes {
//         println!("Attribute {}: {:?}", attribute.0, attribute.1.value());
//     }
// }

// /////// //
// Structs //
// /////// //

#[derive(Debug)]
pub struct IppPrinterState {
    pub queue_name: String,
    pub description: String,
    pub state: PrinterState,
    pub job_count: i32,
    pub state_message: String,
    pub state_reason: String,
}

#[derive(Debug)]
pub struct PrintJobState {
    pub name: String,
    pub id: i32,
    pub state: JobState,
    pub reason: String,
    pub created: DateTime<Utc>,
}

#[derive(Debug)]
pub struct PrintDimension {
    pub name: String,
    pub height: f64,
    pub width: f64,
    pub keyword: String
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn parses_page_sizes_with_the_same_dimensions_separately() {
        // From the Gutenprint PPD of the DNP DS620, where several cutting modes use the same paper.
        let ppd = "*PaperDimension w288h432/4x6:\t\"297.600 460.800\"\n*PaperDimension w288h432-div2/2x6*2:\t\"297.600 460.800\"\n*ImageableArea w288h432/4x6: \"0 0 297.6 460.8\"\n";

        let dimensions = parse_paper_dimensions(ppd);

        assert_eq!(dimensions.len(), 2);
        assert_eq!((dimensions[0].name.as_str(), dimensions[0].keyword.as_str()), ("4x6", "w288h432"));
        assert_eq!((dimensions[1].name.as_str(), dimensions[1].keyword.as_str()), ("2x6*2", "w288h432-div2"));
        assert!((dimensions[1].width - 104.99).abs() < 0.01 && (dimensions[1].height - 162.56).abs() < 0.01);
    }

    #[test]
    fn parses_page_sizes_without_translation_or_decimals() {
        let ppd = "*PaperDimension A4: \"595 842\"\n*PaperDimension Custom.1x1/Custom: \"72 72\"\n";

        let dimensions = parse_paper_dimensions(ppd);

        assert_eq!(dimensions.len(), 2);
        assert_eq!((dimensions[0].name.as_str(), dimensions[0].keyword.as_str()), ("A4", "A4"));
        assert!((dimensions[0].width - 209.9).abs() < 0.1 && (dimensions[0].height - 297.0).abs() < 0.1);
        assert_eq!(dimensions[1].keyword, "Custom.1x1");
    }
}
