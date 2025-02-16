import 'dart:async';
import 'dart:io';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:momento_booth/extensions/build_context_extension.dart';
import 'package:momento_booth/main.dart';
import 'package:momento_booth/managers/_all.dart';
import 'package:momento_booth/models/_all.dart';
import 'package:momento_booth/repositories/serializable/toml_serializable_repository.dart';
import 'package:momento_booth/utils/environment_info.dart';
import 'package:momento_booth/utils/logger.dart';
import 'package:momento_booth/views/base/photo_booth_dialog_page.dart';
import 'package:momento_booth/views/components/dialogs/settings_import_dialog.dart';
import 'package:path/path.dart' as path;
import 'package:super_clipboard/super_clipboard.dart';
import 'package:super_drag_and_drop/super_drag_and_drop.dart';

class MyDropRegion extends StatefulWidget {

  const MyDropRegion({super.key});

  @override
  State<StatefulWidget> createState() => _MyDropRegionState();

}

class _MyDropRegionState extends State<MyDropRegion> with Logger {

  static const tomlFormat = SimpleFileFormat(
    uniformTypeIdentifiers: ['public.toml'],
    mimeTypes: ['application/toml', 'text/x-toml'],
  );

  bool _isDragOver = false;

  List<UpdateRecord>? _updates;
  Settings? _newSettings;

  @override
  Widget build(BuildContext context) {
    return DropRegion(
      formats: const [
        ...Formats.standardFormats,
        tomlFormat,
      ],
      hitTestBehavior: HitTestBehavior.opaque,
      onDropOver: _onDropOver,
      onPerformDrop: _onPerformDrop,
      onDropLeave: _onDropLeave,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.grey[100],
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        padding: EdgeInsets.all(20.0),
        alignment: Alignment.center,
        child: Column(
          children: [
            Icon(LucideIcons.squareMousePointer, size: 48.0, color: Colors.grey[130],),
            SizedBox(height: 8.0),
            Text("Drop settings stub here"),
          ],
        ),
      ),
    );
  }

  DropOperation _onDropOver(DropOverEvent event) {
    setState(() {
      _isDragOver = true;
    });
    return event.session.allowedOperations.firstOrNull ?? DropOperation.none;
  }

  Future<void> _onPerformDrop(PerformDropEvent event) async {
    // Called when user dropped the item. You can now request the data.
    // Note that data must be requested before the performDrop callback
    // is over.
    final item = event.session.items.first;

    // data reader is available now
    final reader = item.dataReader!;
    final name = await reader.getSuggestedName() ?? "unknown";
    logDebug('Dropped file: $name');

    // For macOS, where you get a file URI
    if (reader.canProvide(Formats.fileUri)) {
      reader.getValue<Uri>(Formats.fileUri, (fileUrl) async {
        if (fileUrl != null) {
          final file = File(fileUrl.toFilePath());
          final name = path.basename(file.path);
          final value = await file.readAsString();
          unawaited(_processFile(name, value));
        }
      }, onError: (error) {
        logWarning('Error reading value $error');
      });
    }

    // For Windows, where you get a virtual file
    if (reader.canProvide(tomlFormat)) {
      reader.getFile(tomlFormat, (f) async {
        final valueBytes = await f.readAll();
        final value = String.fromCharCodes(valueBytes);
        final name = f.fileName ?? "unknown";
        unawaited(_processFile(name, value));
      }, onError: (error) {
        logWarning('Error reading file $error');
      });
    }
  }

  Future<void> _processFile(String filename, String content) async {
    final settingsRepo = TomlSerializableRepository(path.join(appDataPath, "Settings.toml"), Settings.fromJson);
    // TomlSerializableRepository<Settings> settingsRepository = getIt<SerialiableRepository<Settings>>();
    final (settings, updates) = await settingsRepo.overlayWithMap(settingsRepo.getMapFromString(content));
    setState(() {
      _updates = updates;
      _newSettings = settings;
    });
    // BuildContextAbstractor is not available, so neither is showUserDialog
    await context.navigator.push(PhotoBoothDialogPage(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Center(child: SettingsImportDialog(onAccept: () {
          // Save the settings using the settings manager
          getIt<SettingsManager>().updateAndSave(settings);
          GoRouter.of(context).pop();
        }, onCancel: () {
          GoRouter.of(context).pop();
        }, updates: updates)),
      ),
      barrierDismissible: true,
    ).createRoute(context));
  }

  void _onDropLeave(DropEvent event) {
    setState(() {
      _isDragOver = false;
    });
  }

}
