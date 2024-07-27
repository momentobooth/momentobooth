use std::{path::PathBuf, str::FromStr, sync::{Arc, Mutex}};

use chrono::{DateTime, Utc};
use ffsend_api::{action::{upload::Upload, params::ParamsData, delete::Delete}, url::Url, client::{Client, ClientConfig}, pipe::ProgressReporter, file::remote_file::RemoteFile};

use crate::frb_generated::StreamSink;

// ///////// //
// Functions //
// ///////// //

pub fn upload_file(host_url: String, file_path: String, download_filename: Option<String>, max_downloads: Option<u8>, expires_after_seconds: Option<u32>, update_sink: StreamSink<FfSendTransferProgress>) {
    // Prepare upload
    let version = ffsend_api::api::Version::V3;
    let url = Url::parse(host_url.as_str()).expect("Could not parse host URL");
    let file = PathBuf::from_str(file_path.as_str()).expect("Could not parse upload file path");
    let name = download_filename;
    let password = None;
    let params = Some(ParamsData::from(max_downloads, expires_after_seconds.map(|n| n as usize)));

    let action = Upload::new(version, url, file, name, password, params);
    let client = Client::new(ClientConfig::default(), true);

    // Initialize reporting and start upload
    let transfer_progress_reporter = Arc::new(Mutex::new(FfSendTransferProgressReporter::new(update_sink)));
    let clone = transfer_progress_reporter.clone();
    let progress_reporter: Arc<Mutex<dyn ProgressReporter>> = transfer_progress_reporter;
    let action_result = action.invoke(&client, Some(&progress_reporter));

    // Send final progress report containing URL
    let file = action_result.expect("Could not upload file");
    let mut progress = clone.lock().expect("Could not acquire lock on ProgressReporter");
    progress.update_from_remote_file(file);
}

pub fn delete_file(file_id: String) {
    let file = serde_json::from_str(file_id.as_str()).expect("Could not deserialize UploadFile from JSON");
    let action = Delete::new(&file, None);
    let client = Client::new(ClientConfig::default(), false);
    let action_result = action.invoke(&client);
    action_result.expect("Could not delete file");
}

// /////// //
// Structs //
// /////// //

#[derive(Debug, Clone)]
pub struct FfSendTransferProgress {
    pub is_finished: bool,
    pub transferred_bytes: u32,
    pub total_bytes: Option<u32>,
    pub download_url: Option<String>,
    pub expire_date: Option<DateTime<Utc>>,

    pub file_id: Option<String>,
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
                transferred_bytes: 0,
                total_bytes: None,
                download_url: None,
                expire_date: None,
                file_id: None,
            },
        }
    }

    fn update_from_remote_file(&mut self, file: RemoteFile) {
        self.current_progress.is_finished = true;
        self.current_progress.download_url = Some(file.download_url(true).to_string());
        self.current_progress.expire_date = if file.expire_uncertain() { None } else { Some(file.expire_at()) };
        self.current_progress.file_id = Some(serde_json::to_string(&file).expect("Could not serialize UploadFile to JSON"));
        let _ = self.stream_sink.add(self.current_progress.clone());
    }
}

impl ProgressReporter for FfSendTransferProgressReporter {
    fn start(&mut self, total: u64) {
        self.current_progress.total_bytes = Some(total as u32);
        let _ = self.stream_sink.add(self.current_progress.clone());
    }

    fn progress(&mut self, progress: u64) {
        self.current_progress.transferred_bytes = progress as u32;
        let _ = self.stream_sink.add(self.current_progress.clone());
    }

    fn finish(&mut self) {
    }
}
