import 'package:momento_booth/src/rust/models/live_view.dart';

extension CameraStateExtension on CameraState {

  static const Duration _timeSinceLastReceivedFrameThreshold = Duration(seconds: 2);

  bool get streamHasProbablyFailed {
    Duration? timeSinceLastReceivedFrame = this.timeSinceLastReceivedFrame;
    return !isStreaming ||
        (timeSinceLastReceivedFrame != null && timeSinceLastReceivedFrame > _timeSinceLastReceivedFrameThreshold);
  } 

}
