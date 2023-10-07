import 'package:fluent_ui/fluent_ui.dart';
import 'package:momento_booth/views/custom_widgets/cards/fluent_setting_card.dart';

class TextDisplayCard extends StatelessWidget {

  final IconData icon;
  final String title;
  final String subtitle;
  final String text;

  const TextDisplayCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    FluentThemeData themeData = FluentTheme.of(context);
    return FluentSettingCard(
      icon: icon,
      title: title,
      subtitle: subtitle,
      child: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: themeData.accentColor,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          text,
          textAlign: TextAlign.right,
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }

}
