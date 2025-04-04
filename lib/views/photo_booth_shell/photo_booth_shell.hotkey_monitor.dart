part of 'photo_booth_shell.dart';

class _HotkeyResponder extends StatelessWidget with Logger {

  final Widget child;

  const _HotkeyResponder({required this.child});

  @override
  Widget build(BuildContext context) {
    bool control = !Platform.isMacOS, meta = Platform.isMacOS;

    return CallbackShortcuts(
      bindings: {
        SingleActivator(LogicalKeyboardKey.keyH, control: control, meta: meta): () => context.router.replaceAll([StartRoute()]),
        SingleActivator(LogicalKeyboardKey.keyM, control: control, meta: meta): () => _toggleManualCollageScreen(context),
      },
      child: child,
    );
  }

  void _toggleManualCollageScreen(BuildContext context) {
    if (context.router.topRoute.name == ManualCollageRoute.name) {
      context.router.replaceAll([StartRoute()]);
    } else {
      context.router.replaceAll([ManualCollageRoute()]);
    }
  }

}
