
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_rust_bridge_example/views/custom_widgets/blocks/fluent_settings_block.dart';
import 'package:flutter_scroll_shadow/flutter_scroll_shadow.dart';

class FluentSettingsPage extends StatefulWidget {

  final String title;
  final List<FluentSettingsBlock> blocks;

  const FluentSettingsPage({
    super.key,
    required this.title,
    required this.blocks,
  });

  @override
  State<FluentSettingsPage> createState() => _FluentSettingsPageState();
}

class _FluentSettingsPageState extends State<FluentSettingsPage> {

  late ScrollController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ScrollController();
  }

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
            child: Text(widget.title, style: theme.typography.title),
          ),
          Expanded(
            child: ScrollShadow(
              color: theme.micaBackgroundColor.toAccentColor().lightest,
              controller: _controller,
              child: ListView(
                controller: _controller,
                children: widget.blocks,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
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
