import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:momento_booth/views/base/build_context_accessor.dart';
import 'package:momento_booth/views/base/custom_route_data.dart';
import 'package:momento_booth/views/base/screen_base.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/share_screen/share_screen_controller.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/share_screen/share_screen_view.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/share_screen/share_screen_view_model.dart';

class ShareRoute extends CustomRouteData {

  const ShareRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => const ShareScreen();

}

class ShareScreen extends ScreenBase<ShareScreenViewModel, ShareScreenController, ShareScreenView> {

  const ShareScreen({super.key});

  @override
  ShareScreenController createController({required ShareScreenViewModel viewModel, required BuildContextAccessor contextAccessor}) {
    return ShareScreenController(viewModel: viewModel, contextAccessor: contextAccessor);
  }

  @override
  ShareScreenView createView({required ShareScreenController controller, required ShareScreenViewModel viewModel, required BuildContextAccessor contextAccessor}) {
    return ShareScreenView(viewModel: viewModel, controller: controller, contextAccessor: contextAccessor);
  }

  @override
  ShareScreenViewModel createViewModel({required BuildContextAccessor contextAccessor}) {
    return ShareScreenViewModel(contextAccessor: contextAccessor);
  }

}
