
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_scroll_shadow/flutter_scroll_shadow.dart';

class FluentSettingsPage extends StatelessWidget {

  final String title;
  final List<Widget> blocks;

  const FluentSettingsPage({
    super.key,
    required this.title,
    required this.blocks,
  });

  @override
  Widget build(BuildContext context) {
    FluentThemeData theme = FluentTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0, left: 16.0, right: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Text(title, style: theme.typography.title),
          ),
          Expanded(
            child: ScrollShadow(
              size: 16,
              color: theme.micaBackgroundColor.toAccentColor().lightest,
              child: ListView(
                children: blocks,
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(top: 16.0),
            child: SizedBox(
              width: double.maxFinite,
              child: InfoBar(title: Text('Changes will be saved automatically')),
            ),
          ),  
        ],
      ),
    );
  }

}
