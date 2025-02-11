part of 'photo_booth.dart';

class _HotkeyResponder extends StatelessWidget with Logger {

  final GoRouter router;
  final Widget child;

  const _HotkeyResponder({required this.router, required this.child});

  @override
  Widget build(BuildContext context) {
    bool control = !Platform.isMacOS, meta = Platform.isMacOS;

    return CallbackShortcuts(
      bindings: {
        SingleActivator(LogicalKeyboardKey.keyH, control: control, meta: meta): () => router.go(StartScreen.defaultRoute),
        SingleActivator(LogicalKeyboardKey.keyM, control: control, meta: meta): _toggleManualCollageScreen,
      },
      child: child,
    );
  }

  void _toggleManualCollageScreen() {
    if (router.currentLocation == ManualCollageScreen.defaultRoute) {
      router.go(StartScreen.defaultRoute);
    } else {
      router.go(ManualCollageScreen.defaultRoute);
    }
  }

}
