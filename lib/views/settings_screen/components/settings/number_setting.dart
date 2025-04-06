
import 'package:fluent_ui/fluent_ui.dart';
import 'package:momento_booth/views/settings_screen/components/settings/setting.dart';

class NumberSetting<T extends num> extends StatefulWidget {

  final IconData icon;
  final String title;
  final String subtitle;
  final ValueGetter<T> value;
  final ValueChanged<T?> onFinishedEditing;
  final num smallChange;
  final Widget? leading;

  const NumberSetting({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onFinishedEditing,
    this.smallChange = 1,
    this.leading,
  });

  @override
  State<NumberSetting<T>> createState() => _NumberSettingState<T>();

}

class _NumberSettingState<T extends num> extends State<NumberSetting<T>> {

  late T _currentValue;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.value();
  }

  @override
  Widget build(BuildContext context) {
    return Setting(
      icon: widget.icon,
      title: widget.title,
      subtitle: widget.subtitle,
      leading: widget.leading,
      setting: SizedBox(
        width: 150,
        child: Focus(
          skipTraversal: true,
          onFocusChange: (hasFocus) => !hasFocus ? widget.onFinishedEditing(_currentValue) : null,
          child: NumberBox<T>(
            value: _currentValue,
            onChanged: (value) => setState(() => _currentValue = value ?? _currentValue),
            smallChange: widget.smallChange,
          ),
        ),
      ),
    );
  }

}
