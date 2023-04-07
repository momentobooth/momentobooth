import 'package:flutter_rust_bridge_example/views/base/screen_controller_base.dart';
import 'package:flutter_rust_bridge_example/views/collage_maker_screen/collage_maker_screen_view_model.dart';

class CollageMakerScreenController extends ScreenControllerBase<CollageMakerScreenViewModel> {

  // Initialization/Deinitialization

  CollageMakerScreenController({
    required super.viewModel,
    required super.contextAccessor,
  });

}
