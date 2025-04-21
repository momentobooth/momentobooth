import 'package:fluent_ui/fluent_ui.dart';

class NeobrutalismTitleFrame extends StatelessWidget {

  final Widget child;

  const NeobrutalismTitleFrame({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 48),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(width: 8),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [BoxShadow(offset: Offset(-12, 12))],
      ),
      child: child,
    );
  }

}
