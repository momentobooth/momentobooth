import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:momento_booth/views/base/screen_view_base.dart';
import 'package:momento_booth/views/components/animations/pulsating_opacity.dart';
import 'package:momento_booth/views/components/dialogs/loading_dialog.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/post_recording_screen/post_recording_screen_controller.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/post_recording_screen/post_recording_screen_view_model.dart';

class PostRecordingScreenView extends ScreenViewBase<PostRecordingScreenViewModel, PostRecordingScreenController> {

  const PostRecordingScreenView({
    required super.viewModel,
    required super.controller,
    required super.contextAccessor,
  });

  @override
  Widget get body {
    return Stack(
      clipBehavior: Clip.none,
      fit: StackFit.expand,
      children: [
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [],
        ),
      ],
    );
  }

}
