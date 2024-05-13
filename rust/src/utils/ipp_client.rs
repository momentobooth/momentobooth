use std::{collections::HashMap, io::Cursor};
use std::io::Read;
use chrono::{DateTime, Utc};

use ipp::prelude::*;
use regex::Regex;

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
fn send_ipp_request(uri: String, ignore_tls_errors: bool, op: Operation) -> IppRequestResponse {
    let uri_p: Uri = uri.parse().unwrap();
    let req = IppRequestResponse::new(
        IppVersion::v1_1(),
        op,
        Some(uri_p.clone())
    );
    let client = IppClient::builder(uri_p).ignore_tls_errors(ignore_tls_errors).build();
    let resp = client.send(req);
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
fn send_ipp_job_request(uri: String, ignore_tls_errors: bool, op: Operation, job_id: i32) -> IppRequestResponse {
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

    let client = IppClient::builder(uri_p).ignore_tls_errors(ignore_tls_errors).build();
    let resp = client.send(req);
    resp.unwrap()
}

pub fn resume_printer(uri: String, ignore_tls_errors: bool) -> bool {
    send_ipp_request(uri, ignore_tls_errors, Operation::ResumePrinter).header().status_code().is_success()
}

pub fn purge_jobs(uri: String, ignore_tls_errors: bool) -> bool {
    send_ipp_request(uri, ignore_tls_errors, Operation::PurgeJobs).header().status_code().is_success()
}

pub fn print_job(uri: String, ignore_tls_errors: bool, job_name: String, pdf_data: Vec<u8>) -> bool {
    let uri_p: Uri = uri.parse().unwrap();
    let pdf_data_cursor = Cursor::new(pdf_data);
    let pdf_data_payload = IppPayload::new(pdf_data_cursor);
    let print_job = IppOperationBuilder::print_job(uri_p.clone(), pdf_data_payload).job_title(job_name);

    let client = IppClient::builder(uri_p).ignore_tls_errors(ignore_tls_errors).build();
    let resp = client.send(print_job.build());
    resp.unwrap().header().status_code().is_success()
}

pub fn restart_job(uri: String, ignore_tls_errors: bool, job_id: i32) -> bool {
    send_ipp_job_request(uri, ignore_tls_errors, Operation::RestartJob, job_id).header().status_code().is_success()
}

pub fn release_job(uri: String, ignore_tls_errors: bool, job_id: i32) -> bool {
    send_ipp_job_request(uri, ignore_tls_errors, Operation::ReleaseJob, job_id).header().status_code().is_success()
}

pub fn cancel_job(uri: String, ignore_tls_errors: bool, job_id: i32) -> bool {
    send_ipp_job_request(uri, ignore_tls_errors, Operation::CancelJob, job_id).header().status_code().is_success()
}

pub fn get_printers(uri: String, ignore_tls_errors: bool) -> Vec<IppPrinterState> {
    let resp = send_ipp_request(uri.clone(), ignore_tls_errors, Operation::CupsGetPrinters);
    let mut vec: Vec<IppPrinterState> = Vec::new();

    for printer in resp.attributes().groups_of(DelimiterTag::PrinterAttributes) {
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
        vec.push(IppPrinterState { queue_name, description, state, job_count, state_message, state_reason });
    }

    vec
}

pub fn get_printer_state(uri: String, ignore_tls_errors: bool) -> IppPrinterState {
    let resp = send_ipp_request(uri.clone(), ignore_tls_errors, Operation::GetPrinterAttributes);

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
    //print_attributes(attributes);
    IppPrinterState { queue_name, description, state, job_count, state_message, state_reason }
}

pub fn get_jobs_states(uri: String, ignore_tls_errors: bool) -> Vec<PrintJobState> {
    let resp = send_ipp_request(uri.clone(), ignore_tls_errors, Operation::GetJobs);
    let mut vec: Vec<PrintJobState> = Vec::new();

    for job in resp.attributes().groups_of(DelimiterTag::JobAttributes) {
        let job_id = job.attributes()["job-id"].value().as_integer().unwrap().clone();
        vec.push(get_job_state(uri.clone(), ignore_tls_errors, job_id));
    }

    // print_attributes(attributes);
    vec
}

fn get_job_state(uri: String, ignore_tls_errors: bool, job_id: i32) -> PrintJobState {
    let resp = send_ipp_job_request(uri.clone(), ignore_tls_errors, Operation::GetJobAttributes, job_id);

    let group = resp.attributes().groups_of(DelimiterTag::JobAttributes).next().unwrap();
    let attributes = group.attributes().clone();

    // print_attributes(attributes.clone());

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
        state: state,
        reason: attributes["job-state-reasons"].value().to_string().clone(),
        created: creation_time,
    }
}

pub fn get_printer_media_dimensions(uri: String, ignore_tls_errors: bool) -> Vec<PrintDimension> {
    let resp = send_ipp_request(uri.clone(), ignore_tls_errors, Operation::GetPrinterAttributes);
    let group = resp.attributes().groups_of(DelimiterTag::PrinterAttributes).next().unwrap();
    let attributes = group.attributes().clone();
    let state: Vec<String> = attributes["media-supported"].value().as_array().unwrap().iter().map(|e| {e.to_string()}).collect();

    let mut dimensions: Vec<PrintDimension> = Vec::new();
    let resp = send_ipp_request(uri.clone(), ignore_tls_errors, Operation::CupsGetPPD);
    let mut payload = resp.into_payload();
    let mut buffer = "".to_string();
    let _ = payload.read_to_string(&mut buffer);
    let re = Regex::new(r#"/(.+):[\t ]+"(\d+\.\d+) (\d+\.\d+)""#).unwrap();
    let conversion_unit = 72.0/25.4;

    for line in buffer.lines() {
        if line.starts_with("*PaperDimension") {
            let caps = re.captures(line).unwrap();
            let name = caps.get(1).unwrap().as_str().to_string();
            let height = caps.get(2).unwrap().as_str().parse::<f64>().unwrap()/conversion_unit;
            let width = caps.get(3).unwrap().as_str().parse::<f64>().unwrap()/conversion_unit;
            let format = &state[dimensions.len()];
            let dim = PrintDimension { name, height, width, keyword: format.to_string() };
            dimensions.push(dim);
        }
    }
    dimensions
}

fn print_attributes(attributes: HashMap<String, IppAttribute>) {
    for attribute in attributes {
        println!("Attribute {}: {:?}", attribute.0, attribute.1.value());
    }
}

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
