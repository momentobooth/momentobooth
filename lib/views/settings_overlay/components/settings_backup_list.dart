import 'package:fluent_ui/fluent_ui.dart';
import 'package:intl/intl.dart';
import 'package:momento_booth/main.dart';
import 'package:momento_booth/models/settings.dart';
import 'package:momento_booth/repositories/serializable/toml_backup_repository.dart';
import 'package:momento_booth/utils/environment_info.dart';
import 'package:momento_booth/utils/logger.dart';
import 'package:momento_booth/views/settings_overlay/components/settings_import_dialog.dart';
import 'package:toml/toml.dart';
import 'package:url_launcher/url_launcher.dart';

/// Lists the backups of the application settings, with actions to create a backup and to restore one.
class SettingsBackupList extends StatefulWidget {

  const SettingsBackupList({super.key});

  @override
  State<SettingsBackupList> createState() => _SettingsBackupListState();

}

class _SettingsBackupListState extends State<SettingsBackupList> with Logger {

  static final DateFormat _dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');

  TomlBackupRepository<Settings> get _repository => getIt<TomlBackupRepository<Settings>>();

  late Future<List<ConfigBackup>> _backups = _repository.list();

  @override
  void initState() {
    super.initState();
    // Refresh when a backup is made elsewhere too, e.g. before an import from the drop region on the same page.
    _repository.revision.addListener(_reload);
  }

  @override
  void dispose() {
    _repository.revision.removeListener(_reload);
    super.dispose();
  }

  void _reload() {
    if (mounted) setState(() => _backups = _repository.list());
  }

  Future<void> _createBackup() async {
    try {
      await _repository.create(ConfigBackupReason.manual, appVersion: appVersionWithBuild);
    } catch (e, s) {
      logError("Could not create a backup", e, s);
      await _showError("Could not create a backup", e);
    }
  }

  Future<void> _showError(String title, Object error) async {
    if (!mounted) return;
    await displayInfoBar(context, builder: (context, close) => InfoBar(
      title: Text(title),
      content: Text(error.toString()),
      severity: InfoBarSeverity.error,
      onClose: close,
    ));
  }

  Future<void> _openFolder() async {
    await _repository.directory.create(recursive: true);
    await launchUrl(Uri.directory(_repository.directory.path));
  }

  Future<void> _restore(ConfigBackup backup) async {
    try {
      Map<String, dynamic> map = TomlDocument.parse(await backup.file.readAsString()).toMap();
      if (!mounted) return;
      await reviewAndApplySettings(context, map, title: "Restore backup from ${_dateFormat.format(backup.createdAt)}");
    } catch (e, s) {
      logError("Could not restore backup ${backup.file.path}", e, s);
      await _showError("Could not restore the backup", e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 12.0,
      children: [
        const Text(
          "A backup of the settings is made when a new version is started, when the settings contain values that this "
          "version does not use, and before importing or restoring settings. The newest 30 backups are kept.",
        ),
        Row(
          spacing: 8.0,
          children: [
            Button(onPressed: _createBackup, child: const Text("Create backup now")),
            Button(onPressed: _openFolder, child: const Text("Open backup folder")),
          ],
        ),
        FutureBuilder(
          future: _backups,
          builder: (context, snapshot) {
            if (snapshot.hasError) return Text("Could not list the backups: ${snapshot.error}");
            if (!snapshot.hasData) return const ProgressRing();
            if (snapshot.data!.isEmpty) return const Text("There are no backups yet.");
            return _table(context, snapshot.data!);
          },
        ),
      ],
    );
  }

  Widget _table(BuildContext context, List<ConfigBackup> backups) {
    TextStyle? headerStyle = FluentTheme.of(context).typography.bodyStrong;
    const EdgeInsets cellPadding = EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0);

    return Table(
      columnWidths: const {
        0: IntrinsicColumnWidth(),
        1: IntrinsicColumnWidth(),
        2: FlexColumnWidth(),
        3: IntrinsicColumnWidth(),
      },
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        TableRow(children: [
          for (final header in ["Created", "Version", "Reason", ""])
            Padding(padding: cellPadding, child: Text(header, style: headerStyle)),
        ]),
        for (final backup in backups)
          TableRow(children: [
            Padding(padding: cellPadding, child: Text(_dateFormat.format(backup.createdAt))),
            Padding(padding: cellPadding, child: Text(backup.appVersion)),
            Padding(padding: cellPadding, child: Text(backup.reason.description)),
            Padding(padding: cellPadding, child: Button(onPressed: () => _restore(backup), child: const Text("Restore…"))),
          ]),
      ],
    );
  }

}
