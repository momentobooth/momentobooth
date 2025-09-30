import 'package:fluent_ui/fluent_ui.dart';

class QuickAction extends StatelessWidget {

  final String title;
  final IconData icon;
  final VoidCallback onPressed;

  const QuickAction({super.key, required this.title, required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: 32,
        children: [Icon(icon, size: 64), Text(title)],
      ),
    );
  }

}
