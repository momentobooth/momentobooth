import 'package:momento_booth/views/base/build_context_accessor.dart';
import 'package:momento_booth/views/base/screen_base.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/post_recording_screen/post_recording_screen_controller.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/post_recording_screen/post_recording_screen_view.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/post_recording_screen/post_recording_screen_view_model.dart';

class PostRecordingScreen extends ScreenBase<PostRecordingScreenViewModel, PostRecordingScreenController, PostRecordingScreenView> {

  static const String defaultRoute = "/post-recording";

  const PostRecordingScreen({super.key});

  @override
  PostRecordingScreenController createController({required PostRecordingScreenViewModel viewModel, required BuildContextAccessor contextAccessor}) {
    return PostRecordingScreenController(viewModel: viewModel, contextAccessor: contextAccessor);
  }

  @override
  PostRecordingScreenView createView({required PostRecordingScreenController controller, required PostRecordingScreenViewModel viewModel, required BuildContextAccessor contextAccessor}) {
    return PostRecordingScreenView(viewModel: viewModel, controller: controller, contextAccessor: contextAccessor);
  }

  @override
  PostRecordingScreenViewModel createViewModel({required BuildContextAccessor contextAccessor}) {
    return PostRecordingScreenViewModel(contextAccessor: contextAccessor);
  }

}
