use std::io::Cursor;
use futures::AsyncReadExt;
use chrono::{DateTime, Utc};

use ipp::prelude::*;
use ipp::value::IppValue::Keyword;
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
    );
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
    );
    req.attributes_mut().add(
        DelimiterTag::OperationAttributes,
        IppAttribute::new(IppAttribute::JOB_ID, IppValue::Integer(job_id)),
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
        .attribute(IppAttribute::new("media", Keyword(media_size)));

    let client = AsyncIppClient::builder(uri_p).ignore_tls_errors(ignore_tls_errors).build();
    let resp = client.send(print_job.build()).await;
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
        let group = printer.attributes().clone();
        let state = group["printer-state"]
            .value()
            .as_enum()
            .and_then(|v| PrinterState::from_i32(*v))
            .unwrap();
        let job_count = group["queued-job-count"].value().as_integer().unwrap().clone();
        let state_message = group["printer-state-message"].value().to_string().clone();
        let queue_name = group["printer-name"].value().to_string().clone();
        let description = group["printer-info"].value().to_string().clone();
        let state_reason = group["printer-state-reasons"].value().to_string().clone();
        IppPrinterState { queue_name, description, state, job_count, state_message, state_reason }
    }).collect()
}

pub async fn get_printer_state(uri: String, ignore_tls_errors: bool) -> IppPrinterState {
    let resp = send_ipp_request(uri.clone(), ignore_tls_errors, Operation::GetPrinterAttributes).await;

    let group = resp.attributes().groups_of(DelimiterTag::PrinterAttributes).next().unwrap();
    let attributes = group.attributes().clone();

    let state = group.attributes()["printer-state"]
        .value()
        .as_enum()
        .and_then(|v| PrinterState::from_i32(*v))
        .unwrap();
    let job_count = attributes["queued-job-count"].value().as_integer().unwrap().clone();
    let state_message = attributes["printer-state-message"].value().to_string().clone();
    let queue_name = attributes["printer-name"].value().to_string().clone();
    let description = attributes["printer-info"].value().to_string().clone();
    let state_reason = attributes["printer-state-reasons"].value().to_string().clone();

    IppPrinterState { queue_name, description, state, job_count, state_message, state_reason }
}

pub async fn get_jobs_states(uri: String, ignore_tls_errors: bool) -> Vec<PrintJobState> {
    let resp = send_ipp_request(uri.clone(), ignore_tls_errors, Operation::GetJobs).await;

    join_all(resp.attributes().groups_of(DelimiterTag::JobAttributes).map(|job| {
        let job_id = job.attributes()["job-id"].value().as_integer().unwrap().clone();
        get_job_state(uri.clone(), ignore_tls_errors, job_id)
    })).await
}

async fn get_job_state(uri: String, ignore_tls_errors: bool, job_id: i32) -> PrintJobState {
    let resp = send_ipp_job_request(uri.clone(), ignore_tls_errors, Operation::GetJobAttributes, job_id).await;

    let group = resp.attributes().groups_of(DelimiterTag::JobAttributes).next().unwrap();
    let attributes = group.attributes().clone();

    let state = group.attributes()["job-state"]
        .value()
        .as_enum()
        .and_then(|v| JobState::from_i32(*v))
        .unwrap();

    let creation_time = DateTime::from_timestamp_millis((attributes["time-at-creation"].value().as_integer().unwrap().clone() as i64) * 1000).unwrap();

    // Not every job seems to have a name
    let job_name = if attributes.get_key_value("job-name").is_some() { attributes["job-name"].value().to_string().clone() } else { "".to_string() };

    PrintJobState {
        name: job_name,
        id: attributes["job-id"].value().as_integer().unwrap().clone(),
        state,
        reason: attributes["job-state-reasons"].value().to_string().clone(),
        created: creation_time,
    }
}

pub async fn get_printer_media_dimensions(uri: String, ignore_tls_errors: bool) -> Vec<PrintDimension> {
    let resp = send_ipp_request(uri.clone(), ignore_tls_errors, Operation::GetPrinterAttributes).await;
    let group = resp.attributes().groups_of(DelimiterTag::PrinterAttributes).next().unwrap();
    let attributes = group.attributes().clone();
    let state: Vec<String> = attributes["media-supported"].value().as_array().unwrap().iter().map(|e| {e.to_string()}).collect();

    let mut dimensions: Vec<PrintDimension> = Vec::new();
    let resp = send_ipp_request(uri.clone(), ignore_tls_errors, Operation::CupsGetPPD).await;
    let mut payload = resp.into_payload();
    let mut buffer = "".to_string();
    let _ = payload.read_to_string(&mut buffer).await;
    let re = Regex::new(r#"/(.+):[\t ]+"(\d+\.\d+) (\d+\.\d+)""#).unwrap();
    let conversion_unit = 72.0/25.4;

    for line in buffer.lines() {
        if line.starts_with("*PaperDimension") {
            let caps = re.captures(line).unwrap();
            let name = caps.get(1).unwrap().as_str().to_string();
            let width = caps.get(2).unwrap().as_str().parse::<f64>().unwrap()/conversion_unit;
            let height = caps.get(3).unwrap().as_str().parse::<f64>().unwrap()/conversion_unit;
            let format = &state[dimensions.len()];
            let dim = PrintDimension { name, height, width, keyword: format.to_string() };
            dimensions.push(dim);
        }
    }
    dimensions
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
