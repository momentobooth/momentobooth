import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_rust_bridge_example/views/custom_widgets/cards/fluent_setting_card.dart';

class FluentSettingsBlock extends StatelessWidget {

  final String title;
  final List<Widget> settings;

  const FluentSettingsBlock({
    super.key,
    required this.title,
    required this.settings,
  });

  @override
  Widget build(BuildContext context) {
    FluentThemeData theme = FluentTheme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.typography.subtitle),
          const SizedBox(height: 8),
          ...settings,
        ],
      ),
    );
  }

}
