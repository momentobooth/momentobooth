import 'package:momento_booth/main.dart';
import 'package:momento_booth/managers/live_view_manager.dart';
import 'package:momento_booth/views/base/screen_controller_base.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/recording_countdown_screen/recording_countdown_screen_view_model.dart';

class RecordingCountdownScreenController extends ScreenControllerBase<RecordingCountdownScreenViewModel> {

  // Initialization/Deinitialization

  RecordingCountdownScreenController({
    required super.viewModel,
    required super.contextAccessor,
  }) {
    getIt<LiveViewManager>().isRecordingLayout = true;
  }

}
