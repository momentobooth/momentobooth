
import 'package:fluent_ui/fluent_ui.dart';
import 'package:momento_booth/views/custom_widgets/cards/fluent_setting_card.dart';

typedef GetValueCallback<T> = T Function();

class NumberInputCard<T extends num> extends StatefulWidget {

  final IconData icon;
  final String title;
  final String subtitle;
  final GetValueCallback<T> value;
  final ValueChanged<T?> onFinishedEditing;
  final num smallChange;

  const NumberInputCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onFinishedEditing,
    this.smallChange = 1,
  });

  @override
  State<NumberInputCard<T>> createState() => _NumberInputCardState<T>();

}

class _NumberInputCardState<T extends num> extends State<NumberInputCard<T>> {

  late T _currentValue;

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
      child: SizedBox(
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
