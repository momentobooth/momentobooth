import 'package:momento_booth/views/base/build_context_accessor.dart';
import 'package:momento_booth/views/base/screen_base.dart';
import 'package:momento_booth/views/collage_maker_screen/collage_maker_screen_controller.dart';
import 'package:momento_booth/views/collage_maker_screen/collage_maker_screen_view.dart';
import 'package:momento_booth/views/collage_maker_screen/collage_maker_screen_view_model.dart';

class CollageMakerScreen extends ScreenBase<CollageMakerScreenViewModel, CollageMakerScreenController, CollageMakerScreenView> {

  const CollageMakerScreen({super.key});

  static const String defaultRoute = "/collage-maker";

  @override
  CollageMakerScreenController createController({required CollageMakerScreenViewModel viewModel, required BuildContextAccessor contextAccessor}) {
    return CollageMakerScreenController(viewModel: viewModel, contextAccessor: contextAccessor);
  }

  @override
  CollageMakerScreenView createView({required CollageMakerScreenController controller, required CollageMakerScreenViewModel viewModel, required BuildContextAccessor contextAccessor}) {
    return CollageMakerScreenView(viewModel: viewModel, controller: controller, contextAccessor: contextAccessor);
  }

  @override
  CollageMakerScreenViewModel createViewModel({required BuildContextAccessor contextAccessor}) {
    return CollageMakerScreenViewModel(contextAccessor: contextAccessor);
  }

}
