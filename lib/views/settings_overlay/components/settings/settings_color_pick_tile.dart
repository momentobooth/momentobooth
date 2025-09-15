
import 'package:fluent_ui/fluent_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:momento_booth/views/settings_overlay/components/settings/settings_tile.dart';

class SettingsColorPickTile extends StatefulWidget {

  final IconData icon;
  final String title;
  final String subtitle;
  final ValueGetter<Color> value;
  final ValueChanged<Color?> onChanged;

  const SettingsColorPickTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  State<SettingsColorPickTile> createState() => _SettingsColorPickTileState();

}

class _SettingsColorPickTileState extends State<SettingsColorPickTile> {

  late Color _currentValue;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.value();
  }

  @override
  Widget build(BuildContext context) {
    return SettingsTile(
      icon: widget.icon,
      title: widget.title,
      subtitle: widget.subtitle,
      setting: Focus(
        skipTraversal: true,
        onFocusChange: (hasFocus) => !hasFocus ? widget.onChanged(_currentValue) : null,
        child: GestureDetector(
          onTap: _showColorPickerDialog,
          child: Container(
            decoration: BoxDecoration(color: _currentValue, borderRadius: BorderRadius.circular(4)),
            height: 32,
            width: 64,
          ),
        ),
      ),
    );
  }

  void _showColorPickerDialog() {
    Color currentColor = _currentValue;
    showDialog(
      context: context,
      builder: (_) {
        return ContentDialog(
          constraints: BoxConstraints.loose(Size.fromWidth(650)),
          content: IntrinsicHeight(
            child: Center(
              child: ColorPicker(
                color: _currentValue,
                onChanged: (color) => currentColor = color,
                orientation: Axis.horizontal,
                isAlphaEnabled: false,
              ),
            ),
          ),
          actions: [
            Button(child: const Text('Cancel'), onPressed: () => context.pop()),
            FilledButton(
              child: const Text('Save'),
              onPressed: () {
                setState(() => _currentValue = currentColor);
                widget.onChanged(currentColor);
                context.pop();
              },
            ),
          ],
        );
      },
    );
  }

}
