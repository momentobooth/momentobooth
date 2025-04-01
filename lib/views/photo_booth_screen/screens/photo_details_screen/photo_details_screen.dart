import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:momento_booth/views/base/build_context_accessor.dart';
import 'package:momento_booth/views/base/custom_route_data.dart';
import 'package:momento_booth/views/base/screen_base.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/photo_details_screen/photo_details_screen_controller.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/photo_details_screen/photo_details_screen_view.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/photo_details_screen/photo_details_screen_view_model.dart';

class PhotoDetailsRoute extends CustomRouteData {

  final String photoId;

  const PhotoDetailsRoute({required this.photoId}) : super(opaque: true, barrierDismissible: true);

  @override
  Widget build(BuildContext context, GoRouterState state) => PhotoDetailsScreen(photoId: photoId);

}

class PhotoDetailsScreen extends ScreenBase<PhotoDetailsScreenViewModel, PhotoDetailsScreenController, PhotoDetailsScreenView> {

  final String photoId;

  const PhotoDetailsScreen({super.key, required this.photoId});

  @override
  PhotoDetailsScreenController createController({required PhotoDetailsScreenViewModel viewModel, required BuildContextAccessor contextAccessor}) {
    return PhotoDetailsScreenController(viewModel: viewModel, contextAccessor: contextAccessor);
  }

  @override
  PhotoDetailsScreenView createView({required PhotoDetailsScreenController controller, required PhotoDetailsScreenViewModel viewModel, required BuildContextAccessor contextAccessor}) {
    return PhotoDetailsScreenView(viewModel: viewModel, controller: controller, contextAccessor: contextAccessor);
  }

  @override
  PhotoDetailsScreenViewModel createViewModel({required BuildContextAccessor contextAccessor}) {
    return PhotoDetailsScreenViewModel(contextAccessor: contextAccessor, photoId: photoId);
  }

}
