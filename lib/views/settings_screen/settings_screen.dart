import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:momento_booth/views/base/build_context_accessor.dart';
import 'package:momento_booth/views/base/custom_route_data.dart';
import 'package:momento_booth/views/base/full_screen_dialog.dart';
import 'package:momento_booth/views/base/screen_base.dart';
import 'package:momento_booth/views/settings_screen/settings_screen_controller.dart';
import 'package:momento_booth/views/settings_screen/settings_screen_view.dart';
import 'package:momento_booth/views/settings_screen/settings_screen_view_model.dart';

part 'settings_screen.g.dart';

@TypedGoRoute<SettingsRoute>(path: '/settings')
class SettingsRoute extends CustomRouteData {

  final SettingsPageKey initialPage;

  const SettingsRoute({this.initialPage = SettingsPageKey.project}) : super(
    enableTransitionOut: false,
    barrierDismissible: true,
    opaque: false,
  );

  @override
  Widget build(BuildContext context, GoRouterState state) => FullScreenPopup(child: SettingsScreen(initialPage: initialPage));

}

class SettingsScreen extends ScreenBase<SettingsScreenViewModel, SettingsScreenController, SettingsScreenView> {

  final SettingsPageKey initialPage;

  const SettingsScreen({super.key, required this.initialPage});

  @override
  SettingsScreenController createController({required SettingsScreenViewModel viewModel, required BuildContextAccessor contextAccessor}) {
    return SettingsScreenController(viewModel: viewModel, contextAccessor: contextAccessor);
  }

  @override
  SettingsScreenView createView({required SettingsScreenController controller, required SettingsScreenViewModel viewModel, required BuildContextAccessor contextAccessor}) {
    return SettingsScreenView(viewModel: viewModel, controller: controller, contextAccessor: contextAccessor, initialPage: initialPage);
  }

  @override
  SettingsScreenViewModel createViewModel({required BuildContextAccessor contextAccessor}) {
    return SettingsScreenViewModel(contextAccessor: contextAccessor);
  }

}
