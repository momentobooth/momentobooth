import 'package:momento_booth/main.dart';
import 'package:momento_booth/managers/live_view_manager.dart';
import 'package:momento_booth/views/base/screen_controller_base.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/post_recording_screen/post_recording_screen_view_model.dart';

class PostRecordingScreenController extends ScreenControllerBase<PostRecordingScreenViewModel> {

  // Initialization/Deinitialization

  PostRecordingScreenController({
    required super.viewModel,
    required super.contextAccessor,
  }) {
    getIt<LiveViewManager>().isRecordingLayout = false;
  }

}
