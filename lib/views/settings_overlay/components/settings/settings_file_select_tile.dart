import 'package:file_selector/file_selector.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:momento_booth/views/settings_overlay/components/settings/settings_tile.dart';

class SettingsFileSelectTile extends StatelessWidget {

  final IconData icon;
  final String title;
  final String subtitle;
  final TextEditingController controller;
  final ValueChanged<String?> onChanged;
  final bool clearable;

  const SettingsFileSelectTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.controller,
    required this.onChanged,
    this.clearable = true,
  });

  @override
  Widget build(BuildContext context) {
    return SettingsTile(
      icon: icon,
      title: title,
      subtitle: subtitle,
      setting: Row(
        children: [
          IconButton(
            icon: const Icon(LucideIcons.folderOpen, size: 24.0),
            onPressed: () async {
              XFile? selectedFile = await openFile();
              if (selectedFile == null) return;
              controller.text = selectedFile.path;
              onChanged(selectedFile.path);
            },
          ),
          const SizedBox(width: 10),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 150),
            child: SizedBox(
              width: 250,
              child: TextBox(
                readOnly: true,
                controller: controller,
                onChanged: onChanged,
                suffix: clearable ? IconButton(
                  icon: const Icon(LucideIcons.x),
                  onPressed: () {
                    controller.clear();
                    onChanged('');
                  },
                ) : null,
                suffixMode: OverlayVisibilityMode.editing,
              ),
            ),
          ),
        ],
      ),
    );
  }

}
