part of 'momento_booth_app.dart';

class _HotkeyResponder extends StatelessWidget {

  final Widget child;

  const _HotkeyResponder({required this.child});

  @override
  Widget build(BuildContext context) {
    bool control = !Platform.isMacOS, meta = Platform.isMacOS;

    return CallbackShortcuts(
      bindings: {
        SingleActivator(LogicalKeyboardKey.keyR, control: control, meta: meta): () => getIt<LiveViewManager>().restoreLiveView(),
        SingleActivator(LogicalKeyboardKey.keyS, control: control, meta: meta): () => SettingsOverlay.openDialog(context),
        SingleActivator(LogicalKeyboardKey.keyF, control: control, meta: meta): () => getIt<WindowManager>().toggleFullscreenSafe(),
        SingleActivator(LogicalKeyboardKey.keyO, control: control, meta: meta): () => getIt<ProjectManager>().browseOpen(),
        SingleActivator(LogicalKeyboardKey.keyL, control: control, meta: meta): _switchToNextLanguage,
        const SingleActivator(LogicalKeyboardKey.enter, alt: true): () => getIt<WindowManager>().toggleFullscreenSafe(),
      },
      child: child,
    );
  }

  void _switchToNextLanguage() {
    int index = Language.values.indexOf(getIt<SettingsManager>().settings.ui.language);
    Language newLanguage = Language.values[(index + 1) % Language.values.length];
    getIt<SettingsManager>().mutateAndSave(
      (settings) => settings.copyWith.ui(language: newLanguage),
    );
  }

}
