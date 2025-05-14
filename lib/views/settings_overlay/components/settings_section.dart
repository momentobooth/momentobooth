import 'package:fluent_ui/fluent_ui.dart';

class SettingsSection extends StatelessWidget {

  final String title;
  final List<Widget> settings;

  const SettingsSection({
    super.key,
    required this.title,
    required this.settings,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: FluentTheme.of(context).typography.subtitle),
          const SizedBox(height: 8),
          ...settings,
        ],
      ),
    );
  }

}
