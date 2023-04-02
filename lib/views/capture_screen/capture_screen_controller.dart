import 'dart:io' show Platform, stdout;

import 'package:flutter_rust_bridge_example/model/photo_state.dart';
import 'package:flutter_rust_bridge_example/utils/sony_remote_photo_capture.dart';
import 'package:flutter_rust_bridge_example/views/base/screen_controller_base.dart';
import 'package:flutter_rust_bridge_example/views/capture_screen/capture_screen_view_model.dart';

class CaptureScreenController extends ScreenControllerBase<CaptureScreenViewModel> {

  // Initialization/Deinitialization

  CaptureScreenController({
    required super.viewModel,
    required super.contextAccessor,
  });

  void captureAndGetPhoto() async {
    // Fixme: This should be a setting
    String os = Platform.operatingSystem;
    String home = "";
    Map<String, String> envVars = Platform.environment;
    if (Platform.isMacOS || Platform.isLinux) {
      home = envVars['HOME']!;
    } else if (Platform.isWindows) {
      home = envVars['UserProfile']!;
    }
    final capturer = SonyRemotePhotoCapture("$home\\Pictures");
    final image = await capturer.captureAndGetPhoto();
    PhotoStateBase.instance.photos.add(image);
  }

}
