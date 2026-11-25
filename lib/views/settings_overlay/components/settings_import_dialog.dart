import 'package:fluent_ui/fluent_ui.dart';
import 'package:momento_booth/app_localizations.dart';
import 'package:momento_booth/repositories/serializable/toml_serializable_repository.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

/// Shows which settings an import (or a backup restore) changes, before applying them.
class SettingsImportDialog extends StatelessWidget {

  final String title;
  final VoidCallback onCancel;
  final VoidCallback onAccept;
  final List<UpdateRecord> updates;
  final List<String> unsupportedPaths;

  const SettingsImportDialog({
    super.key,
    this.title = "Import settings",
    required this.onAccept,
    required this.onCancel,
    required this.updates,
    this.unsupportedPaths = const [],
  });

  @override
  Widget build(BuildContext context) {
    AppLocalizations localizations = AppLocalizations.of(context)!;
    List<UpdateRecord> changed = updates.where((update) => update.isChanged).toList();
    List<UpdateRecord> unchanged = updates.where((update) => !update.isChanged).toList();

    return ContentDialog(
      title: Text(title),
      constraints: const BoxConstraints(maxWidth: 800, maxHeight: 700),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 12.0,
          children: [
            Text("Changed settings (${changed.length})", style: FluentTheme.of(context).typography.bodyStrong),
            if (changed.isEmpty)
              const Text("None of the settings differ from your current settings.")
            else
              _SettingsList(children: [
                for (final update in changed)
                  _SettingRow(path: update.path, value: "${update.hadOldValue ? update.oldValue : '(not set)'}  →  ${update.newValue}"),
              ]),
            if (unsupportedPaths.isNotEmpty)
              InfoBar(
                title: Text("${unsupportedPaths.length} settings are not used by this version and will be ignored"),
                content: Text(unsupportedPaths.join("\n")),
                severity: InfoBarSeverity.warning,
                isLong: true,
              ),
            if (unchanged.isNotEmpty)
              Expander(
                header: Text("Unchanged settings (${unchanged.length})"),
                content: _SettingsList(children: [
                  for (final update in unchanged)
                    _SettingRow(path: update.path, value: "${update.newValue}"),
                ]),
              ),
          ],
        ),
      ),
      actions: [
        Button(
          onPressed: onCancel,
          child: Text(localizations.genericCancelButton),
        ),
        FilledButton(
          onPressed: changed.isEmpty ? null : onAccept,
          child: const Text("Apply"),
        ),
      ],
    );
  }

}

class _SettingsList extends StatelessWidget {

  final List<Widget> children;

  const _SettingsList({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[30]),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 4.0,
        children: children,
      ),
    );
  }

}

class _SettingRow extends StatelessWidget {

  final String path;
  final String value;

  const _SettingRow({required this.path, required this.value});

  @override
  Widget build(BuildContext context) {
    return Text.rich(TextSpan(children: [
      TextSpan(text: "$path: ", style: const TextStyle(fontWeight: FontWeight.bold)),
      TextSpan(text: value),
    ]));
  }

}

@UseCase(name: 'Settings Import Dialog', type: SettingsImportDialog)
Widget settingsImportDialog(BuildContext context) {
  return SettingsImportDialog(
    onAccept: () {},
    onCancel: () {},
    updates: [
      UpdateRecord(path: 'hardware.liveViewFlip', hadOldValue: true, oldValue: 'none', newValue: 'horizontally'),
      UpdateRecord(path: 'ui.primaryColor', hadOldValue: false, oldValue: null, newValue: 4282339765),
      UpdateRecord(path: 'collagePadding', hadOldValue: true, oldValue: 10.0, newValue: 10.0),
      UpdateRecord(path: 'hardware.captureFlip', hadOldValue: true, oldValue: 'none', newValue: 'none'),
    ],
    unsupportedPaths: const ['hardware.usePrinterSettings'],
  );
}
