import 'dart:async';
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
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

  final VoidCallback? onAccept;

  const MyDropRegion({super.key, this.onAccept});

  @override
  State<StatefulWidget> createState() => _MyDropRegionState();

}

class _MyDropRegionState extends State<MyDropRegion> with Logger, TickerProviderStateMixin {

  static const tomlFormat = SimpleFileFormat(
    uniformTypeIdentifiers: ['public.toml'],
    mimeTypes: ['application/toml', 'text/x-toml'],
  );

  set _isDragOver(bool val) {
    if (val) {
      colorController.forward();
    } else {
      colorController.reverse();
    }
  }

  bool imported = false;
  String? error;
  late AnimationController colorController;
  late Animation colorAnimation1, colorAnimation2;

  @override
  void initState() {
    super.initState();

    colorController = AnimationController(
      duration: const Duration(milliseconds: 100), //controll animation duration
      vsync: this,
    )..addListener(() {
        setState(() {});
    });

    final curvedAnimation = CurvedAnimation(parent: colorController, curve: Curves.ease);

    colorAnimation1 = ColorTween(
      begin: Colors.grey[100],
      end: getIt<ProjectManager>().primaryColor,
    ).animate(curvedAnimation);

    colorAnimation2 = ColorTween(
      begin: Colors.grey[130],
      end: getIt<ProjectManager>().primaryColor,
    ).animate(curvedAnimation);
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      _dropRegion(),
      if (imported || error != null)
        SizedBox(height: 16.0),
      if (error != null)
        Text(
          error!,
          style: TextStyle(color: Colors.errorPrimaryColor, fontWeight: FontWeight.bold),
        ),
      if (imported)
        Text(
          "Settings successfully imported",
          style: TextStyle(color: Colors.successPrimaryColor, fontWeight: FontWeight.bold),
        ),
    ]);
  }

  Widget _dropRegion() {
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
            color: colorAnimation1.value,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        padding: EdgeInsets.all(20.0),
        alignment: Alignment.center,
        child: Column(
          children: [
            Icon(LucideIcons.squareMousePointer, size: 48.0, color: colorAnimation2.value),
            SizedBox(height: 8.0),
            Text("Drop settings stub here"),
            SizedBox(height: 8.0),
            Button(onPressed: _onBrowsePress, child: Text("Browse settings file")),
          ],
        ),
      ),
    );
  }

  DropOperation _onDropOver(DropOverEvent event) {
    setState(() =>  _isDragOver = true);
    return event.session.allowedOperations.firstOrNull ?? DropOperation.none;
  }

  void processError(String msg) {
    logError(msg);
    setState(() => error = msg);
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

    // In case of file URI
    if (reader.canProvide(Formats.fileUri)) {
      reader.getValue<Uri>(Formats.fileUri, (fileUrl) async {
        if (fileUrl != null) {
          final file = File(fileUrl.toFilePath());
          final name = path.basename(file.path);
          late final String value;
          try {
            value = await file.readAsString();
          } on Exception catch (e) {
            processError('Error reading file: $e');
            return;
          }
          unawaited(_processFile(name, value));
        }
      }, onError: (error) {
        processError('Error reading file URL: $error');
      });
    }
    // In case of virtual file
    else if (reader.canProvide(tomlFormat)) {
      reader.getFile(tomlFormat, (f) async {
        late final String value;
        try {
          final valueBytes = await f.readAll();
           value = String.fromCharCodes(valueBytes);
        } on Exception catch (e) {
          processError('Error reading virtual file: $e');
        }
        final name = f.fileName ?? "unknown";
        unawaited(_processFile(name, value));
      }, onError: (error) {
        processError('Error reading file: $error');
      });
    }
    // In case of plain text drag and drop
    else if (reader.canProvide(Formats.plainText)) {
      reader.getValue<String>(Formats.plainText, (content) async {
        if (content == null) return;
        final name = "plaintext drag";
        unawaited(_processFile(name, content));
      }, onError: (error) {
        logWarning('Error reading file $error');
      });
    } else {
      processError("Could not read the dropped content. Is it the right type?");
    }
  }

  Future<void> _onBrowsePress() async {
    var tomlXTypeGroup = XTypeGroup(
      label: "TOML files",
      extensions: [".toml"],
      mimeTypes: tomlFormat.mimeTypes,
      uniformTypeIdentifiers: tomlFormat.uniformTypeIdentifiers,
    );
    final file = await openFile(acceptedTypeGroups: [tomlXTypeGroup]);
    if (file == null) return;
    final content = await file.readAsString();
    final name = path.basename(file.path);
    unawaited(_processFile(name, content));
  }

  Future<void> _processFile(String filename, String content) async {
    final settingsRepo = TomlSerializableRepository(path.join(appDataPath, "Settings.toml"), Settings.fromJson);
    // Ensure settings file exists
    await getIt<SettingsManager>().save();

    if (!filename.toLowerCase().endsWith(".toml")) {
      logWarning("Filename $filename does not end with .toml, trying to use anyway.");
    }

    late final Map<String, dynamic> overlayMap;
    try {
      overlayMap = settingsRepo.getMapFromString(content);
    } on Exception catch (e) {
      processError("Error parsing overlay file: $e");
      return;
    }

    late final Settings settings;
    late final List<UpdateRecord> updates;
    try {
      (settings, updates) = await settingsRepo.overlayWithMap(overlayMap);
    } on Exception catch (e) {
      processError("Error applying overlay: $e");
      return;
    }

    setState(() => _isDragOver = false);
    // BuildContextAbstractor is not available, so neither is showUserDialog
    await Navigator.of(context, rootNavigator: true).push(PhotoBoothDialogPage(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Center(child: SettingsImportDialog(onAccept: () {
          // Save the settings using the settings manager
          getIt<SettingsManager>().updateAndSave(settings);
          setState(() {
            imported = true;
            error = null;
          });
          widget.onAccept?.call();
          GoRouter.of(context).pop();
        }, onCancel: () {
          GoRouter.of(context).pop();
        }, updates: updates)),
      ),
      barrierDismissible: true,
    ).createRoute(context));
  }

  void _onDropLeave(DropEvent event) {
    setState(() => _isDragOver = false);
  }

  @override
  void dispose() {
    colorController.dispose();
    super.dispose();
  }

}
