import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_rust_bridge_example/theme/momento_booth_theme.dart';
import 'package:flutter_rust_bridge_example/theme/momento_booth_theme_data.dart';
import 'package:flutter_rust_bridge_example/views/start_screen/start_screen_controller.dart';
import 'package:flutter_rust_bridge_example/views/start_screen/start_screen_view.dart';
import 'package:flutter_rust_bridge_example/views/start_screen/start_screen_view_model.dart';
import 'package:go_router/go_router.dart';

// Simple Flutter code. If you are not familiar with Flutter, this may sounds a bit long. But indeed
// it is quite trivial and Flutter is just like that. Please refer to Flutter's tutorial to learn Flutter.

void main() => runApp(const App());

class App extends StatefulWidget {
  const App({Key? key}) : super(key: key);

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {

  final GoRouter _router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) {
          StartScreenViewModel viewModel = StartScreenViewModel();
          StartScreenController controller = StartScreenController(viewModel: viewModel);
          return StartScreenView(viewModel: viewModel, controller: controller);
        },
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return MomentoBoothTheme(
      data: MomentoBoothThemeData.defaults(),
      child: Builder(
        builder: (BuildContext context) {
          MomentoBoothThemeData themeData = MomentoBoothTheme.dataOf(context);
          return WidgetsApp.router(
            routeInformationParser: _router.routeInformationParser,
            routerDelegate: _router.routerDelegate,
            color: themeData.primaryColor,
            builder: (context, child) {
              return ColoredBox(
                color: themeData.defaultPageBackgroundColor,
                child: child,
              );
            },
          );
        },
      ),
    );
  }

}
