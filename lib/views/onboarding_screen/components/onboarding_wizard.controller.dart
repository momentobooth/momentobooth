part of 'onboarding_wizard.dart';

class WizardProvider extends InheritedWidget {

  final WizardController controller;

  const WizardProvider({
    required this.controller,
    required super.child,
    super.key,
  });

  @override
  bool updateShouldNotify(WizardProvider oldWidget) {
    return oldWidget.controller != controller;
  }

  static WizardController of(BuildContext context) {
    final provider = context.dependOnInheritedWidgetOfExactType<WizardProvider>();
    if (provider == null) {
      throw FlutterError(
        'WizardProvider.of() called with a context that does not contain a WizardProvider.',
      );
    }
    return provider.controller;
  }

}

class WizardController {

  int currentIndex = 0;

  final List<Widget> pages;

  WizardController(this.pages);

  bool get canGoBack => currentIndex > 0;
  bool get canGoNext => currentIndex < pages.length - 1;

  void next(BuildContext context) {
    if (canGoNext) {
      currentIndex++;
      Navigator.push(
        context,
        _OnboardingPageRoute(builder: (_) => pages[currentIndex]),
      );
    }
  }

  void previous(BuildContext context) {
    if (canGoBack) {
      currentIndex--;
      Navigator.pop(context);
    }
  }

}
