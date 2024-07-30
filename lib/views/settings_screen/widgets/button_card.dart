import 'package:fluent_ui/fluent_ui.dart';
import 'package:momento_booth/views/custom_widgets/cards/fluent_setting_card.dart';

class ButtonCard extends StatelessWidget {

  final IconData icon;
  final String title;
  final String subtitle;
  final String buttonText;
  final VoidCallback onPressed;

  const ButtonCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.buttonText,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return FluentSettingCard(
      icon: icon,
      title: title,
      subtitle: subtitle,
      child: Button(
        onPressed: onPressed,
        child: Text(buttonText),
      ),
    );
  }

}
