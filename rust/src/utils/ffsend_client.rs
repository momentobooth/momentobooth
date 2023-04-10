use std::{path::PathBuf, str::FromStr, sync::{Arc, Mutex}};

use ffsend_api::{action::upload::Upload, url::Url, client::{Client, ClientConfig}, pipe::ProgressReporter};
use flutter_rust_bridge::StreamSink;

// ///////// //
// Functions //
// ///////// //

pub fn upload_file(host_url: String, file_path: String, download_filename: Option<String>, update_sink: StreamSink<FfSendTransferProgress>) {
    let version = ffsend_api::api::Version::V3;
    let url = Url::parse(host_url.as_str()).unwrap();
    let file = PathBuf::from_str(file_path.as_str()).unwrap();
    let name = download_filename;
    let password = Option::None;
    let params = Option::None;

    let action = Upload::new(version, url, file, name, password, params);
    let client = Client::new(ClientConfig::default(), true);

    let transfer_progress_reporter = Arc::new(Mutex::new(FfSendTransferProgressReporter::new(update_sink.clone())));
    let clone = transfer_progress_reporter.clone();
    let progress_reporter: Arc<Mutex<dyn ProgressReporter>> = transfer_progress_reporter;
    let action_result = action.invoke(&client, Option::Some(&progress_reporter));

    // Send final progress report containing URL
    let file = action_result.expect("Could not upload file");
    let mut progress = clone.lock().expect("Could not acquire lock on ProgressReporter").current_progress.clone();
    progress.is_finished = true;
    progress.download_url = file.download_url(true).to_string();
    update_sink.add(progress);
}

// /////// //
// Structs //
// /////// //

#[derive(Debug, Clone)]
pub struct FfSendTransferProgress {
    pub is_finished: bool,
    pub total_bytes: u64,
    pub transferred_bytes: u64,
    pub download_url: String,
}

pub struct FfSendTransferProgressReporter {
    stream_sink: StreamSink<FfSendTransferProgress>,
    current_progress: FfSendTransferProgress,
}

impl FfSendTransferProgressReporter {
    fn new(update_sink: StreamSink<FfSendTransferProgress>) -> FfSendTransferProgressReporter {
        FfSendTransferProgressReporter {
            stream_sink: update_sink,
            current_progress: FfSendTransferProgress {
                is_finished: false,
                total_bytes: 0,
                transferred_bytes: 0,
                download_url: "".to_string(),
            },
        }
    }
}

impl ProgressReporter for FfSendTransferProgressReporter {
    fn start(&mut self, total: u64) {
        self.current_progress.total_bytes = total;
        self.stream_sink.add(self.current_progress.clone());
    }

    fn progress(&mut self, progress: u64) {
        self.current_progress.transferred_bytes = progress;
        self.stream_sink.add(self.current_progress.clone());
    }

    fn finish(&mut self) {
    }
}
