//! Integration tests of the CUPS functions against a real CUPS server.
//!
//! They need a CUPS server with a paused queue named `MomentoBoothTest`, see "CUPS integration tests" in `documentation/src/dev_setup.md`. Start one with `just test-cups`, which also
//! runs these tests. Without the `CUPS_TEST_URI` environment variable the tests return immediately.
//!
//! The tests share one queue, so they run in sequence, guarded by `QUEUE_LOCK`.

use std::io::Cursor;
use std::sync::LazyLock;

use ipp::attribute::IppAttrWithName;
use ipp::prelude::*;
use tokio::sync::Mutex;

use crate::api::cups::*;
use crate::utils::ipp_client;

const QUEUE: &str = "MomentoBoothTest";

/// A one page PDF of 4x6 inch, small enough to send in every test.
const TEST_PDF: &[u8] = b"%PDF-1.4
1 0 obj << /Type /Catalog /Pages 2 0 R >> endobj
2 0 obj << /Type /Pages /Kids [3 0 R] /Count 1 >> endobj
3 0 obj << /Type /Page /Parent 2 0 R /MediaBox [0 0 288 432] >> endobj
trailer << /Root 1 0 R >>
%%EOF
";

static QUEUE_LOCK: LazyLock<Mutex<()>> = LazyLock::new(|| Mutex::new(()));

/// Returns the server from the environment, or `None` to skip the test.
fn server() -> Option<CupsServerInfo> {
    let Ok(uri) = std::env::var("CUPS_TEST_URI") else {
        eprintln!("CUPS_TEST_URI is not set, skipping CUPS test");
        return None;
    };
    Some(CupsServerInfo {
        uri,
        ignore_tls_errors: false,
        username: std::env::var("CUPS_TEST_USERNAME").unwrap_or_default(),
        password: std::env::var("CUPS_TEST_PASSWORD").unwrap_or_default(),
    })
}

fn queue_uri(server: &CupsServerInfo) -> Uri {
    cups_build_url(server, Some(QUEUE.to_string())).parse().unwrap()
}

/// Sends an operation that the application itself does not use, to set up or clean up the queue.
async fn send(server: &CupsServerInfo, request: IppRequestResponse) -> IppRequestResponse {
    let client = AsyncIppClient::builder(queue_uri(server)).build();
    let response = client.send(request).await.unwrap();
    assert!(response.header().status_code().is_success(), "{:?}", response.header().status_code());
    response
}

/// Cancels all jobs and pauses the queue, the state every test starts from.
async fn reset_queue(server: &CupsServerInfo) {
    let uri = queue_uri(server);
    send(server, IppRequestResponse::new(IppVersion::v1_1(), Operation::PausePrinter, Some(uri.clone())).unwrap()).await;
    send(server, IppRequestResponse::new(IppVersion::v1_1(), Operation::PurgeJobs, Some(uri)).unwrap()).await;
}

/// Prints like `cups_print_job`, but fails the test when CUPS does not accept the job.
async fn print(server: &CupsServerInfo, name: &str, media: &str) {
    let printed = ipp_client::print_job(cups_build_url(server, Some(QUEUE.to_string())), false, name.to_string(), TEST_PDF.to_vec(), media.to_string()).await;
    assert!(printed, "CUPS did not accept print job {name} with media {media}");
}

async fn print_test_job(server: &CupsServerInfo, name: &str) {
    print(server, name, "w288h432").await;
}

#[tokio::test]
async fn lists_the_test_queue() {
    let Some(server) = server() else { return };
    let _lock = QUEUE_LOCK.lock().await;
    reset_queue(&server).await;

    let printers = cups_get_printers(server).await;

    let printer = printers.iter().find(|p| p.queue_name == QUEUE).expect("test queue not listed");
    assert_eq!(printer.description, "MomentoBooth test printer");
    assert!(matches!(printer.state, PrinterState::Stopped));
}

#[tokio::test]
async fn gets_the_printer_state() {
    let Some(server) = server() else { return };
    let _lock = QUEUE_LOCK.lock().await;
    reset_queue(&server).await;
    print_test_job(&server, "state").await;

    let state = cups_get_printer_state(server, QUEUE.to_string()).await;

    assert_eq!(state.queue_name, QUEUE);
    assert!(matches!(state.state, PrinterState::Stopped));
    assert_eq!(state.job_count, 1);
    assert!(state.state_reason.contains("paused"), "{}", state.state_reason);
}

#[tokio::test]
async fn gets_the_media_dimensions() {
    let Some(server) = server() else { return };
    let _lock = QUEUE_LOCK.lock().await;

    let dimensions = cups_get_printer_media_dimensions(server, QUEUE.to_string()).await;

    // The PPD of the DNP DS620 has 18 page sizes, several with the same paper, which CUPS lists only 11 times in media-supported.
    assert_eq!(dimensions.len(), 18, "{dimensions:?}");
    // The PPD gives the size of the paper including the bleed, 297.6 x 460.8 points for both.
    for (name, keyword) in [("4x6", "w288h432"), ("2x6*2", "w288h432-div2")] {
        let size = dimensions.iter().find(|d| d.name == name).unwrap_or_else(|| panic!("{name} not found"));
        assert_eq!(size.keyword, keyword);
        assert!((size.width - 104.99).abs() < 0.1, "{size:?}");
        assert!((size.height - 162.56).abs() < 0.1, "{size:?}");
    }
}

#[tokio::test]
async fn prints_with_the_media_of_a_cutting_mode() {
    let Some(server) = server() else { return };
    let _lock = QUEUE_LOCK.lock().await;
    reset_queue(&server).await;
    let dimensions = cups_get_printer_media_dimensions(server.clone(), QUEUE.to_string()).await;
    let strips = dimensions.iter().find(|d| d.name == "2x6*2").expect("2x6*2 not found");

    print(&server, "strips", &strips.keyword).await;

    let jobs = cups_get_jobs_states(server.clone(), QUEUE.to_string()).await;
    let mut request = IppRequestResponse::new(IppVersion::v1_1(), Operation::GetJobAttributes, Some(queue_uri(&server))).unwrap();
    request.attributes_mut().add(DelimiterTag::OperationAttributes, IppValue::new_integer(jobs[0].id).with_name(IppAttribute::JOB_ID).unwrap());
    let response = send(&server, request).await;
    let job = response.attributes().groups_of(DelimiterTag::JobAttributes).next().unwrap();
    assert_eq!(job.get("media").unwrap().value().to_string(), "w288h432-div2");
}

#[tokio::test]
async fn prints_a_job() {
    let Some(server) = server() else { return };
    let _lock = QUEUE_LOCK.lock().await;
    reset_queue(&server).await;

    print_test_job(&server, "MomentoBooth test job").await;

    let jobs = cups_get_jobs_states(server, QUEUE.to_string()).await;
    assert_eq!(jobs.len(), 1, "{jobs:?}");
    assert_eq!(jobs[0].name, "MomentoBooth test job");
    assert!(matches!(jobs[0].state, JobState::Pending), "{jobs:?}");
}

#[tokio::test]
async fn releases_a_held_job() {
    let Some(server) = server() else { return };
    let _lock = QUEUE_LOCK.lock().await;
    reset_queue(&server).await;

    let held_job = IppOperationBuilder::print_job(queue_uri(&server), IppPayload::new(Cursor::new(TEST_PDF.to_vec())))
        .job_title("held")
        .attribute(IppValue::new_keyword("indefinite").with_name("job-hold-until").unwrap())
        .build()
        .unwrap();
    send(&server, held_job.into()).await;
    let jobs = cups_get_jobs_states(server.clone(), QUEUE.to_string()).await;
    assert!(matches!(jobs[0].state, JobState::PendingHeld), "{jobs:?}");

    cups_release_job(server.clone(), QUEUE.to_string(), jobs[0].id).await;

    let jobs = cups_get_jobs_states(server, QUEUE.to_string()).await;
    assert!(matches!(jobs[0].state, JobState::Pending), "{jobs:?}");
}

#[tokio::test]
async fn resumes_the_printer() {
    let Some(server) = server() else { return };
    let _lock = QUEUE_LOCK.lock().await;
    reset_queue(&server).await;

    cups_resume_printer(server.clone(), QUEUE.to_string()).await;

    let state = cups_get_printer_state(server.clone(), QUEUE.to_string()).await;
    assert!(!matches!(state.state, PrinterState::Stopped), "{state:?}");
    reset_queue(&server).await;
}
