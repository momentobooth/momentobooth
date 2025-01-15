import 'package:fluent_ui/fluent_ui.dart';
import 'package:momento_booth/app/shell/onboarding_page.dart';
import 'package:momento_booth/app/shell/widgets/wizard_pages/status_page.dart';

class Wizard extends StatelessWidget {

  const Wizard({super.key});

  @override
  Widget build(BuildContext context) {
    return Acrylic(
      elevation: 16.0,
      luminosityAlpha: 0.9,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.0)),
      child: Navigator(
      ),
    );
  }

}

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
        FluentPageRoute(builder: (_) => pages[currentIndex]),
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
