import 'package:momento_booth/rust_bridge/library_api.generated.dart';

extension CameraStateExtension on CameraState {

  static const Duration _timeSinceLastReceivedFrameThreshold = Duration(seconds: 2);

  bool get streamHasProbablyFailed {
    Duration? timeSinceLastReceivedFrame = this.timeSinceLastReceivedFrame;
    return !isStreaming ||
        (timeSinceLastReceivedFrame != null && timeSinceLastReceivedFrame > _timeSinceLastReceivedFrameThreshold);
  } 

}
