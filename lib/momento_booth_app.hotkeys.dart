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
        SingleActivator(LogicalKeyboardKey.keyD, control: control, meta: meta): _switchToCvdSimulation,
        const SingleActivator(LogicalKeyboardKey.enter, alt: true): () => getIt<WindowManager>().toggleFullscreenSafe(),
      },
      child: child,
    );
  }

  void _switchToNextLanguage() {
    final usableValues = Language.definedValues;
    // If no language is selected, set to the current settings language first to start iterating from there
    if (getIt<WindowManager>().selectedLanguage == null) {
      var projectLanguage = getIt<ProjectManager>().settings.language;
      if (projectLanguage != Language.noLanguage) {
        getIt<WindowManager>().setLanguage(projectLanguage);
      } else {
        getIt<WindowManager>().setLanguage(getIt<SettingsManager>().settings.ui.language);
      }
    }
    int index = usableValues.indexOf(getIt<WindowManager>().selectedLanguage!);
    Language newLanguage = usableValues[(index + 1) % usableValues.length];
    getIt<WindowManager>().setLanguage(newLanguage);
  }

  void _switchToCvdSimulation() {
    int index = ColorVisionDeficiency.values.indexOf(getIt<SettingsManager>().settings.debug.simulateCvd);
    ColorVisionDeficiency newCvd = ColorVisionDeficiency.values[(index + 1) % ColorVisionDeficiency.values.length];
    getIt<SettingsManager>().mutateAndSave(
      (settings) => settings.copyWith.debug(simulateCvd: newCvd),
    );
  }

}
