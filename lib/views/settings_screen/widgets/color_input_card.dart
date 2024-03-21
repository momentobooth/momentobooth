
import 'package:csslib/parser.dart' as css_parser;
import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:momento_booth/views/custom_widgets/cards/fluent_setting_card.dart';

typedef GetValueCallback<T> = T Function();

class ColorInputCard extends StatefulWidget {

  final IconData icon;
  final String title;
  final String subtitle;
  final GetValueCallback<String> value;
  final ValueChanged<String?> onFinishedEditing;

  const ColorInputCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onFinishedEditing,
  });

  @override
  State<ColorInputCard> createState() => _ColorInputCardState();

}

class _ColorInputCardState extends State<ColorInputCard> {

  late String _currentValue;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.value();
  }

  @override
  Widget build(BuildContext context) {
    Color currentColor = Color(css_parser.Color.hex('FF${_currentValue.substring(1)}').argbValue);

    return FluentSettingCard(
      icon: widget.icon,
      title: widget.title,
      subtitle: widget.subtitle,
      child: Focus(
        skipTraversal: true,
        onFocusChange: (hasFocus) => !hasFocus ? widget.onFinishedEditing(_currentValue) : null,
        child: ColorIndicator(
          color: currentColor,
          onSelect: () async {
            Color pickedColor = await showColorPickerDialog(
              context,
              currentColor,
              pickersEnabled: const <ColorPickerType, bool>{
                ColorPickerType.wheel: true,
                ColorPickerType.primary: false,
                ColorPickerType.accent: false,
              },
              backgroundColor: Colors.white,
            );
            setState(() => _currentValue = '#${pickedColor.value.toRadixString(16).toUpperCase().substring(2)}');
            widget.onFinishedEditing(_currentValue);
          },
        ),
      ),
    );
  }

}
