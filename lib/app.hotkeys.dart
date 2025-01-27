part of 'app.dart';

class _HotkeyResponder extends StatelessWidget {

  final GoRouter router;
  final Widget child;

  const _HotkeyResponder({required this.router, required this.child});

  @override
  Widget build(BuildContext context) {
    bool control = !Platform.isMacOS, meta = Platform.isMacOS;

    return CallbackShortcuts(
      bindings: {
        SingleActivator(LogicalKeyboardKey.keyR, control: control, meta: meta): () => getIt<LiveViewManager>().restoreLiveView(),
        SingleActivator(LogicalKeyboardKey.keyS, control: control, meta: meta): () {
          if (router.currentLocation == "/settings") {
            // Make sure any overlays are also closed (e.g. dropdowns)
            while (router.currentLocation == "/settings") {
              router.pop();
            }
          } else {
            router.push("/settings");
          }
        },
        SingleActivator(LogicalKeyboardKey.keyF, control: control, meta: meta): () => getIt<WindowManager>().toggleFullscreen(),
        const SingleActivator(LogicalKeyboardKey.enter, alt: true): () => getIt<WindowManager>().toggleFullscreen(),
      },
      child: child,
    );
  }

}
