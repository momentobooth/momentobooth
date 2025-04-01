part of 'photo_booth_shell.dart';

class _HotkeyResponder extends StatelessWidget with Logger {

  final Widget child;

  const _HotkeyResponder({required this.child});

  @override
  Widget build(BuildContext context) {
    bool control = !Platform.isMacOS, meta = Platform.isMacOS;

    return CallbackShortcuts(
      bindings: {
        SingleActivator(LogicalKeyboardKey.keyH, control: control, meta: meta): () => GoRouter.of(context).go(const StartRoute().location),
        SingleActivator(LogicalKeyboardKey.keyM, control: control, meta: meta): () => _toggleManualCollageScreen(context),
      },
      child: child,
    );
  }

  void _toggleManualCollageScreen(BuildContext context) {
    GoRouter router = GoRouter.of(context);
    if (router.currentLocation == const ManualCollageRoute().location) {
      router.go(const StartRoute().location);
    } else {
      router.go(const ManualCollageRoute().location);
    }
  }

}
