import 'package:momento_booth/views/base/build_context_accessor.dart';
import 'package:momento_booth/views/base/screen_base.dart';
import 'package:momento_booth/views/gallery_screen/gallery_screen_controller.dart';
import 'package:momento_booth/views/gallery_screen/gallery_screen_view_model.dart';
import 'package:momento_booth/views/gallery_screen/gallery_screen_view.dart';

class GalleryScreen extends ScreenBase<GalleryScreenViewModel, GalleryScreenController, GalleryScreenView> {

  static const String defaultRoute = "/gallery";

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
