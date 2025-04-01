import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:momento_booth/views/base/build_context_accessor.dart';
import 'package:momento_booth/views/base/custom_route_data.dart';
import 'package:momento_booth/views/base/screen_base.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/multi_capture_screen/multi_capture_screen_controller.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/multi_capture_screen/multi_capture_screen_view.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/multi_capture_screen/multi_capture_screen_view_model.dart';

class MultiCaptureRoute extends CustomRouteData {

  MultiCaptureRoute() : super(key: UniqueKey());

  @override
  Widget build(BuildContext context, GoRouterState state) => MultiCaptureScreen();

}

class MultiCaptureScreen extends ScreenBase<MultiCaptureScreenViewModel, MultiCaptureScreenController, MultiCaptureScreenView> {

  const MultiCaptureScreen({super.key});

  @override
  MultiCaptureScreenController createController({required MultiCaptureScreenViewModel viewModel, required BuildContextAccessor contextAccessor}) {
    return MultiCaptureScreenController(viewModel: viewModel, contextAccessor: contextAccessor);
  }

  @override
  MultiCaptureScreenView createView({required MultiCaptureScreenController controller, required MultiCaptureScreenViewModel viewModel, required BuildContextAccessor contextAccessor}) {
    return MultiCaptureScreenView(viewModel: viewModel, controller: controller, contextAccessor: contextAccessor);
  }

  @override
  MultiCaptureScreenViewModel createViewModel({required BuildContextAccessor contextAccessor}) {
    return MultiCaptureScreenViewModel(contextAccessor: contextAccessor);
  }

}
