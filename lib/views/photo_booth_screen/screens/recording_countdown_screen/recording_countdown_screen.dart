import 'package:momento_booth/views/base/build_context_accessor.dart';
import 'package:momento_booth/views/base/screen_base.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/recording_countdown_screen/recording_countdown_screen_controller.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/recording_countdown_screen/recording_countdown_screen_view.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/recording_countdown_screen/recording_countdown_screen_view_model.dart';

class RecordingCountdownScreen extends ScreenBase<RecordingCountdownScreenViewModel, RecordingCountdownScreenController, RecordingCountdownScreenView> {

  static const String defaultRoute = "/video-recording";

  const RecordingCountdownScreen({super.key});

  @override
  RecordingCountdownScreenController createController({required RecordingCountdownScreenViewModel viewModel, required BuildContextAccessor contextAccessor}) {
    return RecordingCountdownScreenController(viewModel: viewModel, contextAccessor: contextAccessor);
  }

  @override
  RecordingCountdownScreenView createView({required RecordingCountdownScreenController controller, required RecordingCountdownScreenViewModel viewModel, required BuildContextAccessor contextAccessor}) {
    return RecordingCountdownScreenView(viewModel: viewModel, controller: controller, contextAccessor: contextAccessor);
  }

  @override
  RecordingCountdownScreenViewModel createViewModel({required BuildContextAccessor contextAccessor}) {
    return RecordingCountdownScreenViewModel(contextAccessor: contextAccessor);
  }

}
