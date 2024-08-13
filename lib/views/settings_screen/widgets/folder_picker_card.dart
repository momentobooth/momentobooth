import 'package:file_selector/file_selector.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:momento_booth/views/custom_widgets/cards/fluent_setting_card.dart';

class FolderPickerCard extends StatelessWidget {

  final IconData icon;
  final String title;
  final String subtitle;
  final TextEditingController controller;
  final ValueChanged<String?> onChanged;

  const FolderPickerCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return FluentSettingCard(
      icon: icon,
      title: title,
      subtitle: subtitle,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(LucideIcons.folderOpen, size: 24.0),
            onPressed: () async {
              String? selectedDirectory =
                  await getDirectoryPath(initialDirectory: controller.text);
              if (selectedDirectory == null) return;
              controller.text = selectedDirectory;
              onChanged(selectedDirectory);
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
              ),
            ),
          ),
        ],
      ),
    );
  }

}
