import 'package:momento_booth/views/base/build_context_accessor.dart';
import 'package:momento_booth/views/base/screen_base.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/navigation_screen/navigation_screen_controller.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/navigation_screen/navigation_screen_view.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/navigation_screen/navigation_screen_view_model.dart';

class NavigationScreen extends ScreenBase<NavigationScreenViewModel, NavigationScreenController, NavigationScreenView> {

  static const String defaultRoute = "/navigation";

  const NavigationScreen({super.key});

  @override
  NavigationScreenController createController({required NavigationScreenViewModel viewModel, required BuildContextAccessor contextAccessor}) {
    return NavigationScreenController(viewModel: viewModel, contextAccessor: contextAccessor);
  }

  @override
  NavigationScreenView createView({required NavigationScreenController controller, required NavigationScreenViewModel viewModel, required BuildContextAccessor contextAccessor}) {
    return NavigationScreenView(viewModel: viewModel, controller: controller, contextAccessor: contextAccessor);
  }

  @override
  NavigationScreenViewModel createViewModel({required BuildContextAccessor contextAccessor}) {
    return NavigationScreenViewModel(contextAccessor: contextAccessor);
  }

}
