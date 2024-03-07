use std::error::Error;
use std::collections::HashMap;
use chrono::{DateTime, NaiveDateTime, Utc};

use ipp::prelude::*;

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

fn resume_printer(uri: String) -> bool {
    send_ipp_request(uri, Operation::ResumePrinter).header().status_code().is_success()
}

fn purge_jobs(uri: String) -> bool {
    send_ipp_request(uri, Operation::PurgeJobs).header().status_code().is_success()
}

fn restart_job(uri: String, job_id: i32) -> bool {
    send_ipp_job_request(uri, Operation::RestartJob, job_id).header().status_code().is_success()
}

fn release_job(uri: String, job_id: i32) -> bool {
    send_ipp_job_request(uri, Operation::ReleaseJob, job_id).header().status_code().is_success()
}

fn cancel_job(uri: String, job_id: i32) -> bool {
    send_ipp_job_request(uri, Operation::CancelJob, job_id).header().status_code().is_success()
}

#[derive(Debug)]
pub struct MyPrinterState {
    name: String,
    state: PrinterState,
    job_count: i32,
    state_message: String,
    state_reason: String
}

fn get_printer_state(uri: String) -> MyPrinterState {
    // let uri_p: Uri = uri.parse().unwrap();
    // let operation = IppOperationBuilder::get_printer_attributes(uri_p.clone()).build();
    // let client = IppClient::new(uri_p);
    // let resp = client.send(operation).unwrap();
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
    MyPrinterState { name, state, job_count, state_message, state_reason }
}

fn get_jobs(uri: String) -> Vec<MyJobState> {
    // let uri_p: Uri = uri.parse().unwrap();
    // let operation = IppOperationBuilder::get_jobs(uri_p.clone()).build();
    // let client = IppClient::new(uri_p);
    // let resp = client.send(operation).unwrap();
    let resp = send_ipp_request(uri.clone(), Operation::GetJobs);
    let mut vec: Vec<MyJobState> = Vec::new();

    for job in resp.attributes().groups_of(DelimiterTag::JobAttributes) {
        let job_id = job.attributes()["job-id"].value().as_integer().unwrap().clone();
        vec.push(get_jobs_state(uri.clone(), job_id));
    }

    // print_attributes(attributes);
    vec
}

#[derive(Debug)]
pub struct MyJobState {
    name: String,
    id: i32,
    state: JobState,
    message: String,
    reason: String,
    created: DateTime<Utc>
}

fn get_jobs_state(uri: String, job_id: i32) -> MyJobState {
    // let uri_p: Uri = uri.parse().unwrap();
    // let operation = IppOperationBuilder::get_job_attributes(uri_p.clone(), job_id).build();
    // let client = IppClient::new(uri_p);
    // let resp = client.send(operation).unwrap();
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

    MyJobState {
        name: attributes["job-name"].value().to_string().clone(),
        id: attributes["job-id"].value().as_integer().unwrap().clone(),
        state: state,
        message: attributes["job-printer-state-message"].value().to_string().clone(),
        reason: attributes["job-state-reasons"].value().to_string().clone(),
        created: creation_time,
    }
}

fn print_attributes(attributes: HashMap<String, IppAttribute>) {
    for attribute in attributes {
        println!("Attribute {}: {:?}", attribute.0, attribute.1.value());
    }
}
