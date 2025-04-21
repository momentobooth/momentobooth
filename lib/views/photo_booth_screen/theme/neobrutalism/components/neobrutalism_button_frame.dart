import 'package:flutter/widgets.dart';

class NeobrutalismButtonFrame extends StatelessWidget {

  final Set<WidgetState> states;
  final double radius;
  final Widget child;

  const NeobrutalismButtonFrame({super.key, required this.states, required this.radius, required this.child});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      margin:
          states.contains(WidgetState.pressed)
              ? const EdgeInsets.fromLTRB(0, 12, 12, 0)
              : const EdgeInsets.fromLTRB(12, 0, 0, 12),
      duration: Duration(milliseconds: 120),
      curve: Curves.easeOutCirc,
      decoration:
          states.contains(WidgetState.pressed)
              ? BoxDecoration(borderRadius: BorderRadius.circular(radius), boxShadow: [BoxShadow(offset: Offset.zero)])
              : BoxDecoration(borderRadius: BorderRadius.circular(radius), boxShadow: [BoxShadow(offset: Offset(-12, 12))]),
      child: child,
    );
  }

}
