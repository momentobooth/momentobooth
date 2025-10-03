import 'package:fluent_ui/fluent_ui.dart';

class QuickToggle extends StatelessWidget {

  final String title;
  final IconData icon;
  final bool checked;
  final ValueChanged onChanged;

  const QuickToggle({super.key, required this.title, required this.icon, required this.checked, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return ToggleButton(
      checked: checked,
      onChanged: onChanged,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: 32,
        children: [Icon(icon, size: 64), Text(title)],
      ),
    );
  }

}
