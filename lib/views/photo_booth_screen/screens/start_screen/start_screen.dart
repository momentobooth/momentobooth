import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:momento_booth/views/base/build_context_accessor.dart';
import 'package:momento_booth/views/base/custom_route_data.dart';
import 'package:momento_booth/views/base/screen_base.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/start_screen/start_screen_controller.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/start_screen/start_screen_view.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/start_screen/start_screen_view_model.dart';

class StartRoute extends CustomRouteData {

  const StartRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => const StartScreen();

}

class StartScreen extends ScreenBase<StartScreenViewModel, StartScreenController, StartScreenView> {

  const StartScreen({super.key});

  @override
  StartScreenController createController({required StartScreenViewModel viewModel, required BuildContextAccessor contextAccessor}) {
    return StartScreenController(viewModel: viewModel, contextAccessor: contextAccessor);
  }

  @override
  StartScreenView createView({required StartScreenController controller, required StartScreenViewModel viewModel, required BuildContextAccessor contextAccessor}) {
    return StartScreenView(viewModel: viewModel, controller: controller, contextAccessor: contextAccessor);
  }

  @override
  StartScreenViewModel createViewModel({required BuildContextAccessor contextAccessor}) {
    return StartScreenViewModel(contextAccessor: contextAccessor);
  }

}
