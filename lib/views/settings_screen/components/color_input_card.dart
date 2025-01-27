
import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:momento_booth/views/settings_screen/components/fluent_setting_card.dart';

typedef GetValueCallback<T> = T Function();

class ColorInputCard extends StatefulWidget {

  final IconData icon;
  final String title;
  final String subtitle;
  final GetValueCallback<Color> value;
  final ValueChanged<Color?> onChanged;

  const ColorInputCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  State<ColorInputCard> createState() => _ColorInputCardState();

}

class _ColorInputCardState extends State<ColorInputCard> {

  late Color _currentValue;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.value();
  }

  @override
  Widget build(BuildContext context) {
    return FluentSettingCard(
      icon: widget.icon,
      title: widget.title,
      subtitle: widget.subtitle,
      child: Focus(
        skipTraversal: true,
        onFocusChange: (hasFocus) => !hasFocus ? widget.onChanged(_currentValue) : null,
        child: ColorIndicator(
          color: _currentValue,
          onSelect: () async {
            Color pickedColor = await showColorPickerDialog(
              context,
              _currentValue,
              pickersEnabled: const <ColorPickerType, bool>{
                ColorPickerType.wheel: true,
                ColorPickerType.primary: false,
                ColorPickerType.accent: false,
              },
              backgroundColor: Colors.white,
            );

            if (pickedColor != _currentValue) {
              setState(() => _currentValue = pickedColor);
              widget.onChanged(_currentValue);
            }
          },
        ),
      ),
    );
  }

}
