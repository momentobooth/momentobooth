
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_rust_bridge_example/views/custom_widgets/blocks/fluent_settings_block.dart';

class FluentSettingsPage extends StatelessWidget {

  final String title;
  final List<FluentSettingsBlock> blocks;

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
            child: ListView(
              children: blocks,
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

class OuterBoxShadow extends BoxShadow {
  
  const OuterBoxShadow({
    Color color = const Color(0xFF000000),
    Offset offset = Offset.zero,
    double blurRadius = 0.0,
  }) : super(color: color, offset: offset, blurRadius: blurRadius);

  @override
  Paint toPaint() {
    final Paint result = Paint()
      ..color = color
      ..maskFilter = MaskFilter.blur(BlurStyle.outer, blurSigma);
    assert(() {
      if (debugDisableShadows) result.maskFilter = null;
      return true;
    }());
    return result;
  }

}
