import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:momento_booth/views/base/build_context_accessor.dart';
import 'package:momento_booth/views/base/custom_route_data.dart';
import 'package:momento_booth/views/base/screen_base.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/gallery_screen/gallery_screen_controller.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/gallery_screen/gallery_screen_view.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/gallery_screen/gallery_screen_view_model.dart';

class GalleryRoute extends CustomRouteData {

  const GalleryRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => const GalleryScreen();

}

class GalleryScreen extends ScreenBase<GalleryScreenViewModel, GalleryScreenController, GalleryScreenView> {

  const GalleryScreen({super.key});

  @override
  GalleryScreenController createController({required GalleryScreenViewModel viewModel, required BuildContextAccessor contextAccessor}) {
    return GalleryScreenController(viewModel: viewModel, contextAccessor: contextAccessor);
  }

  @override
  GalleryScreenView createView({required GalleryScreenController controller, required GalleryScreenViewModel viewModel, required BuildContextAccessor contextAccessor}) {
    return GalleryScreenView(viewModel: viewModel, controller: controller, contextAccessor: contextAccessor);
  }

  @override
  GalleryScreenViewModel createViewModel({required BuildContextAccessor contextAccessor}) {
    return GalleryScreenViewModel(contextAccessor: contextAccessor);
  }

}
