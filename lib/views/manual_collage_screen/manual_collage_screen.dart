import 'package:momento_booth/views/base/build_context_accessor.dart';
import 'package:momento_booth/views/base/screen_base.dart';
import 'package:momento_booth/views/manual_collage_screen/manual_collage_screen_controller.dart';
import 'package:momento_booth/views/manual_collage_screen/manual_collage_screen_view_model.dart';
import 'package:momento_booth/views/manual_collage_screen/manual_collage_screen_view.dart';

class ManualCollageScreen extends ScreenBase<ManualCollageScreenViewModel, ManualCollageScreenController, ManualCollageScreenView> {
  
  static const String defaultRoute = "/manual-collage";

  const ManualCollageScreen({super.key});

  @override
  ManualCollageScreenController createController({required ManualCollageScreenViewModel viewModel, required BuildContextAccessor contextAccessor}) {
    return ManualCollageScreenController(viewModel: viewModel, contextAccessor: contextAccessor);
  }

  @override
  ManualCollageScreenView createView({required ManualCollageScreenController controller, required ManualCollageScreenViewModel viewModel, required BuildContextAccessor contextAccessor}) {
    return ManualCollageScreenView(viewModel: viewModel, controller: controller, contextAccessor: contextAccessor);
  }

  @override
  ManualCollageScreenViewModel createViewModel({required BuildContextAccessor contextAccessor}) {
    return ManualCollageScreenViewModel(contextAccessor: contextAccessor);
  }

}
