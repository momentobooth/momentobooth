import 'package:flutter/widgets.dart';

class NeobrutalismButtonFrame extends StatelessWidget {

  final Set<WidgetState> states;
  final double radius;
  final double shadowOffset;
  final Widget child;

  const NeobrutalismButtonFrame({super.key, required this.states, required this.radius, required this.shadowOffset, required this.child});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      margin:
          states.contains(WidgetState.pressed)
              ? EdgeInsets.fromLTRB(shadowOffset, shadowOffset, 0, 0)
              : EdgeInsets.fromLTRB(0, 0, shadowOffset, shadowOffset),
      duration: Duration(milliseconds: 120),
      curve: Curves.easeOutCirc,
      decoration:
          states.contains(WidgetState.pressed)
              ? BoxDecoration(borderRadius: BorderRadius.circular(radius), boxShadow: [BoxShadow(offset: Offset.zero)])
              : BoxDecoration(borderRadius: BorderRadius.circular(radius), boxShadow: [BoxShadow(offset: Offset(shadowOffset, shadowOffset))]),
      child: child,
    );
  }

}
