import 'dart:async';

import 'package:mobx/mobx.dart';
import 'package:momento_booth/main.dart';
import 'package:momento_booth/managers/settings_manager.dart';
import 'package:momento_booth/models/settings.dart';
import 'package:momento_booth/src/rust/api/ffsend.dart';
import 'package:momento_booth/utils/logger.dart';

/// Time the progress ring is left at 100% before the QR code is revealed.
const Duration _uploadedRevealDelay = Duration(milliseconds: 500);

/// Time an upload keeps showing progress before the failure is revealed.
const Duration _failedRevealDelay = Duration(seconds: 1);

enum FfSendUploadStatus {
  idle,
  uploading,
  uploaded,
  failed,
}

/// The file to upload, and the name it should be downloaded under.
typedef FfSendUploadFile = ({String filePath, String downloadFilename});

/// Observable state of a single "share this photo with a QR code" upload.
///
/// The upload itself either resolves to a URL or throws [FfSendUploadError]; the Rust side enforces
/// the configured timeouts, so this only has to translate that into something the UI can observe.
class FfSendUpload with Logger {

  /// Called every time an upload completes successfully.
  final void Function()? onUploaded;

  final Observable<FfSendUploadStatus> _status = Observable(FfSendUploadStatus.idle);
  final Observable<double?> _progress = Observable(null);
  final Observable<String?> _downloadUrl = Observable(null);

  /// Incremented per attempt, so a superseded or disposed upload stops updating the state.
  int _attempt = 0;

  FfSendUpload({this.onUploaded});

  FfSendUploadStatus get status => _status.value;

  /// Upload progress in the range 0..1, or `null` while the total size is not known yet.
  double? get progress => _progress.value;

  /// Download URL of the last successful upload, or `null` if there is none.
  String? get downloadUrl => _downloadUrl.value;

  /// Starts a new upload, replacing any upload that is still running.
  ///
  /// [prepare] resolves the file to upload; failures while preparing are reported like any other
  /// upload failure.
  Future<void> start(Future<FfSendUploadFile> Function() prepare) async {
    final int attempt = ++_attempt;
    _setState(FfSendUploadStatus.uploading, progress: 0);

    try {
      final FfSendUploadFile file = await prepare();
      final OutputSettings settings = getIt<SettingsManager>().settings.output;
      logDebug("Uploading ${file.filePath} to ${settings.firefoxSendServerUrl}");

      final FfSendUploadResult result = await ffsendUploadFile(
        request: FfSendUploadRequest(
          hostUrl: settings.firefoxSendServerUrl,
          filePath: file.filePath,
          downloadFilename: file.downloadFilename,
          controlTimeout: settings.firefoxSendControlCommandTimeout,
          transferTimeout: settings.firefoxSendTransferTimeout,
        ),
        onProgress: (progress) => _onProgress(attempt, progress),
      );

      logDebug("Upload complete, expires at ${result.expiresAt}");
      _setState(FfSendUploadStatus.uploading, progress: 1);
      await Future.delayed(_uploadedRevealDelay);
      if (attempt != _attempt) return;

      _setState(FfSendUploadStatus.uploaded, downloadUrl: result.downloadUrl);
      onUploaded?.call();
    } catch (e, s) {
      logError(_describe(e), e, s);
      await Future.delayed(_failedRevealDelay);
      if (attempt != _attempt) return;

      _setState(FfSendUploadStatus.failed);
    }
  }

  void _onProgress(int attempt, FfSendUploadProgress progress) {
    if (attempt != _attempt) return;

    final int totalBytes = progress.totalBytes.toInt();
    // An empty file has nothing to divide by; an indeterminate ring beats a NaN progress.
    _setState(
      FfSendUploadStatus.uploading,
      progress: totalBytes == 0 ? null : (progress.transferredBytes.toInt() / totalBytes).clamp(0.0, 1.0),
    );
  }

  /// Turns an upload failure into a log line that says what to actually fix.
  String _describe(Object error) {
    return switch (error) {
      FfSendUploadError_InvalidHostUrl(:final field0) => "The Firefox Send server URL is not usable: $field0",
      FfSendUploadError_FileNotReadable(:final field0) => "Could not read the photo to upload: $field0",
      FfSendUploadError_Connect(:final field0) => "Could not reach the Firefox Send server: $field0",
      FfSendUploadError_Rejected(:final field0) => "The Firefox Send server rejected the upload: $field0",
      FfSendUploadError_Transfer(:final field0) => "The upload was interrupted: $field0",
      FfSendUploadError_Crypto(:final field0) => "Could not encrypt the photo: $field0",
      FfSendUploadError_Timeout(:final field0) => "The upload timed out $field0",
      _ => "Upload failed",
    };
  }

  void _setState(FfSendUploadStatus status, {double? progress, String? downloadUrl}) {
    runInAction(() {
      _status.value = status;
      _progress.value = progress;
      _downloadUrl.value = downloadUrl;
    });
  }

  /// Abandons any running upload and prevents further state updates.
  void dispose() {
    _attempt++;
  }

}
