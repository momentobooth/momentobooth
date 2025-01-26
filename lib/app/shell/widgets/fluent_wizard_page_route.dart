import 'package:animations/animations.dart';
import 'package:fluent_ui/fluent_ui.dart';

class FluentWizardPageRoute extends FluentPageRoute {

  final WidgetBuilder _builder;

  FluentWizardPageRoute({required super.builder}) : _builder = builder;

  @override
  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
    return Semantics(
      scopesRoute: true,
      explicitChildNodes: true,
      child: SharedAxisTransition(
        animation: animation,
        secondaryAnimation: secondaryAnimation,
        transitionType: SharedAxisTransitionType.horizontal,
        child: _builder(context),
      ),
    );
  }

  @override
  Duration get transitionDuration => const Duration(milliseconds: 600);

}
