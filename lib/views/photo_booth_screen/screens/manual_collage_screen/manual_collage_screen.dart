import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:momento_booth/views/base/build_context_accessor.dart';
import 'package:momento_booth/views/base/custom_route_data.dart';
import 'package:momento_booth/views/base/screen_base.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/manual_collage_screen/manual_collage_screen_controller.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/manual_collage_screen/manual_collage_screen_view.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/manual_collage_screen/manual_collage_screen_view_model.dart';

class ManualCollageRoute extends CustomRouteData {

  const ManualCollageRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => const ManualCollageScreen();

}

class ManualCollageScreen extends ScreenBase<ManualCollageScreenViewModel, ManualCollageScreenController, ManualCollageScreenView> {

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
