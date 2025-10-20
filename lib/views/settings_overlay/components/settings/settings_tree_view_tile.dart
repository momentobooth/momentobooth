import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:momento_booth/views/settings_overlay/components/settings/settings_tile.dart';

class SettingsTreeViewTile<TValue> extends StatelessWidget {

  final IconData icon;
  final String title;
  final String subtitle;
  final List<ComboBoxItem<TValue>> items;
  final ValueGetter<List<TValue>> value;
  final ValueChanged<List<TValue>> onChanged;
  final Widget? prefixWidget;

  const SettingsTreeViewTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.items,
    required this.value,
    required this.onChanged,
    this.prefixWidget,
  });

  TreeViewItem get item => TreeViewItem(
    content: Text('Languages'),
    children: [
      for (final item in items)
        TreeViewItem(
          content: item.child,
          value: item.value,
          selected: value().contains(item.value),
        ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return SettingsTile(
      icon: icon,
      title: title,
      subtitle: subtitle,
      leading: prefixWidget,
      setting: Observer(builder: (_) {
        return TreeView(
          items: [item],
          selectionMode: TreeViewSelectionMode.multiple,
          onSelectionChanged: (selectedItems) async {
            final selectedValues = selectedItems.map((e) => e.value as TValue).toList();
            onChanged(selectedValues);
          },
        );
      }),
    );
  }

}
