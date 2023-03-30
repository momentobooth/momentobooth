import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_rust_bridge_example/extensions/build_context_extension.dart';
import 'package:flutter_rust_bridge_example/theme/momento_booth_theme.dart';
import 'package:flutter_rust_bridge_example/theme/momento_booth_theme_data.dart';
import 'package:flutter_rust_bridge_example/views/base/build_context_accessor.dart';
import 'package:flutter_rust_bridge_example/views/base/fade_transition_page.dart';
import 'package:flutter_rust_bridge_example/views/capture_screen/capture_screen_controller.dart';
import 'package:flutter_rust_bridge_example/views/capture_screen/capture_screen_view.dart';
import 'package:flutter_rust_bridge_example/views/capture_screen/capture_screen_view_model.dart';
import 'package:flutter_rust_bridge_example/views/choose_capture_mode_screen/choose_capture_mode_screen_controller.dart';
import 'package:flutter_rust_bridge_example/views/choose_capture_mode_screen/choose_capture_mode_screen_view.dart';
import 'package:flutter_rust_bridge_example/views/choose_capture_mode_screen/choose_capture_mode_screen_view_model.dart';
import 'package:flutter_rust_bridge_example/views/start_screen/start_screen_controller.dart';
import 'package:flutter_rust_bridge_example/views/start_screen/start_screen_view.dart';
import 'package:flutter_rust_bridge_example/views/start_screen/start_screen_view_model.dart';
import 'package:go_router/go_router.dart';

part 'main.routes.dart';

void main() => runApp(const App());

class App extends StatefulWidget {

  const App({Key? key}) : super(key: key);

  @override
  State<App> createState() => _AppState();

}

class _AppState extends State<App> {

  final GoRouter _router = GoRouter(routes: rootRoutes);

  @override
  Widget build(BuildContext context) {
    return MomentoBoothTheme(
      data: MomentoBoothThemeData.defaults(),
      child: Builder(
        builder: (BuildContext context) {
          return WidgetsApp.router(
            routeInformationParser: _router.routeInformationParser,
            routerDelegate: _router.routerDelegate,
            color: context.theme.primaryColor,
            builder: (context, child) {
              return ColoredBox(
                color: context.theme.defaultPageBackgroundColor,
                child: child,
              );
            },
          );
        },
      ),
    );
  }

}
