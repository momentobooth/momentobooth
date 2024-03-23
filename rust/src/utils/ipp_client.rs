use std::{collections::HashMap, io::Cursor};
use chrono::{DateTime, Utc};

use ipp::{operation::builder::PrintJobBuilder, prelude::*};

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
fn send_ipp_request(uri: String, op: Operation) -> IppRequestResponse {
    let uri_p: Uri = uri.parse().unwrap();
    let req = IppRequestResponse::new(
        IppVersion::v1_1(),
        op,
        Some(uri_p.clone())
    );
    let client = IppClient::new(uri_p);
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
fn send_ipp_job_request(uri: String, op: Operation, job_id: i32) -> IppRequestResponse {
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

    let client = IppClient::new(uri_p);
    let resp = client.send(req);
    resp.unwrap()
}

pub fn resume_printer(uri: String) -> bool {
    send_ipp_request(uri, Operation::ResumePrinter).header().status_code().is_success()
}

pub fn purge_jobs(uri: String) -> bool {
    send_ipp_request(uri, Operation::PurgeJobs).header().status_code().is_success()
}

pub fn print_job(uri: String, job_name: String, pdf_data: Vec<u8>) -> bool {
    let uri_p: Uri = uri.parse().unwrap();
    let pdf_data_cursor = Cursor::new(pdf_data);
    let pdf_data_payload = IppPayload::new(pdf_data_cursor);
    let print_job = IppOperationBuilder::print_job(uri_p.clone(), pdf_data_payload).job_title(job_name);

    let client = IppClient::new(uri_p);
    let resp = client.send(print_job.build());
    resp.unwrap().header().status_code().is_success()
}

pub fn restart_job(uri: String, job_id: i32) -> bool {
    send_ipp_job_request(uri, Operation::RestartJob, job_id).header().status_code().is_success()
}

pub fn release_job(uri: String, job_id: i32) -> bool {
    send_ipp_job_request(uri, Operation::ReleaseJob, job_id).header().status_code().is_success()
}

pub fn cancel_job(uri: String, job_id: i32) -> bool {
    send_ipp_job_request(uri, Operation::CancelJob, job_id).header().status_code().is_success()
}

pub fn get_printer_state(uri: String) -> IppPrinterState {
    let resp = send_ipp_request(uri.clone(), Operation::GetPrinterAttributes);

    let group = resp.attributes().groups_of(DelimiterTag::PrinterAttributes).next().unwrap();
    let attributes = group.attributes().clone();

    let state = group.attributes()["printer-state"]
        .value()
        .as_enum()
        .and_then(|v| PrinterState::from_i32(*v))
        .unwrap();
    let job_count = attributes["queued-job-count"].value().as_integer().unwrap().clone();
    let state_message = attributes["printer-state-message"].value().to_string().clone();
    let name = attributes["printer-name"].value().to_string().clone();
    let state_reason = attributes["printer-state-reasons"].value().to_string().clone();
    //print_attributes(attributes);
    IppPrinterState { name, state, job_count, state_message, state_reason }
}

pub fn get_jobs_states(uri: String) -> Vec<PrintJobState> {
    let resp = send_ipp_request(uri.clone(), Operation::GetJobs);
    let mut vec: Vec<PrintJobState> = Vec::new();

    for job in resp.attributes().groups_of(DelimiterTag::JobAttributes) {
        let job_id = job.attributes()["job-id"].value().as_integer().unwrap().clone();
        vec.push(get_job_state(uri.clone(), job_id));
    }

    // print_attributes(attributes);
    vec
}

fn get_job_state(uri: String, job_id: i32) -> PrintJobState {
    let resp = send_ipp_job_request(uri.clone(), Operation::GetJobAttributes, job_id);

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
    pub name: String,
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
