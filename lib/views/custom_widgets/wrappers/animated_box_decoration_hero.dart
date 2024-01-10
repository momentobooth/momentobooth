import 'package:flutter/widgets.dart';

class AnimatedBoxDecorationHero extends StatelessWidget {

  final String tag;
  final Widget child;
  final Decoration decoration;

  const AnimatedBoxDecorationHero({
    super.key,
    required this.tag,
    required this.child,
    this.decoration = const BoxDecoration(),
  });

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: tag,
      flightShuttleBuilder: (context, animation, direction, fromContext, toContext) {
        Decoration from = fromContext.findAncestorWidgetOfExactType<AnimatedBoxDecorationHero>()!.decoration;
        Decoration to = toContext.findAncestorWidgetOfExactType<AnimatedBoxDecorationHero>()!.decoration;

        return AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            return Align(
              child: DecoratedBox(
                decoration: (direction == HeroFlightDirection.push
                        ? Decoration.lerp(from, to, animation.value)
                        : Decoration.lerp(to, from, animation.value)) ??
                    const BoxDecoration(),
                child: child,
              ),
            );
          },
          child: child,
        );
      },
      child: DecoratedBox(
        decoration: decoration,
        child: child,
      ),
    );
  }

}
