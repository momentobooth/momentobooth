import 'package:fluent_ui/fluent_ui.dart';

class SettingsValueChip extends StatelessWidget {

  final String text;
  final Color? color;

  const SettingsValueChip({
    super.key,
    required this.text,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color ?? FluentTheme.of(context).accentColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        textAlign: TextAlign.right,
        style: const TextStyle(color: Colors.white),
      ),
    );
  }

}
