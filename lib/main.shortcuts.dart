part of 'main.dart';

class _AppShortcuts extends StatelessWidget {

  final VoidCallback onNavigateToHome;
  final VoidCallback onRestoreLiveView;
  final VoidCallback onToggleSettingsOverlay;
  final VoidCallback onOpenManualCollageScreen;
  final VoidCallback onToggleFullScreen;
  final Widget child;

  const _AppShortcuts({
    required this.onNavigateToHome,
    required this.onRestoreLiveView,
    required this.onToggleSettingsOverlay,
    required this.onOpenManualCollageScreen,
    required this.onToggleFullScreen,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    bool control = !Platform.isMacOS, meta = Platform.isMacOS;

    return Shortcuts(
      shortcuts: <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.keyH, control: control, meta: meta): const _NavigateToHomeIntent(),
        SingleActivator(LogicalKeyboardKey.keyR, control: control, meta: meta): const _RestoreLiveViewIntent(),
        SingleActivator(LogicalKeyboardKey.keyS, control: control, meta: meta): const _ToggleSettingsOverlayIntent(),
        SingleActivator(LogicalKeyboardKey.keyM, control: control, meta: meta): const _OpenManualCollageScreenIntent(),
        SingleActivator(LogicalKeyboardKey.keyF, control: control, meta: meta): const _ToggleFullScreenIntent(),
        const SingleActivator(LogicalKeyboardKey.enter, alt: true): const _ToggleFullScreenIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          _NavigateToHomeIntent: CallbackAction(onInvoke: (_) => onNavigateToHome()),
          _RestoreLiveViewIntent: CallbackAction(onInvoke: (_) => onRestoreLiveView()),
          _ToggleSettingsOverlayIntent: CallbackAction(onInvoke: (_) => onToggleSettingsOverlay()),
          _OpenManualCollageScreenIntent: CallbackAction(onInvoke: (_) => onOpenManualCollageScreen()),
          _ToggleFullScreenIntent: CallbackAction(onInvoke: (_) => onToggleFullScreen()),
        },
        child: child,
      ),
    );
  }

}

class _NavigateToHomeIntent extends Intent {
  const _NavigateToHomeIntent();
}

class _RestoreLiveViewIntent extends Intent {
  const _RestoreLiveViewIntent();
}

class _ToggleSettingsOverlayIntent extends Intent {
  const _ToggleSettingsOverlayIntent();
}

class _OpenManualCollageScreenIntent extends Intent {
  const _OpenManualCollageScreenIntent();
}

class _ToggleFullScreenIntent extends Intent {
  const _ToggleFullScreenIntent();
}
