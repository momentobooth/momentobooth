import 'package:fluent_ui/fluent_ui.dart';

class SettingsTile extends StatelessWidget {

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget setting;
  final Widget? leading;

  const SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.setting,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 1),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        spacing: 20,
        children: [
          Icon(icon),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title),
                Text(subtitle, style: FluentTheme.of(context).typography.caption!.copyWith(
                  color: Colors.grey[100],
                )),
              ],
            ),
          ),
          if (leading != null) leading!,
          setting,
        ],
      ),
    );
  }

}
