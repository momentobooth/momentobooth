import 'package:auto_route/annotations.dart';
import 'package:momento_booth/views/base/build_context_accessor.dart';
import 'package:momento_booth/views/base/screen_base.dart';
import 'package:momento_booth/views/photo_booth_shell/screens/photo_details_screen/photo_details_screen_controller.dart';
import 'package:momento_booth/views/photo_booth_shell/screens/photo_details_screen/photo_details_screen_view.dart';
import 'package:momento_booth/views/photo_booth_shell/screens/photo_details_screen/photo_details_screen_view_model.dart';

@RoutePage()
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
