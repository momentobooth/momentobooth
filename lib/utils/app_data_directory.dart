import 'dart:io';

import 'package:path/path.dart' as path;

/// Files that are copied from the default data directory into an overridden one that does not have them yet, so a
/// new data directory starts from the current configuration instead of from scratch.
const List<String> seededAppDataFileNames = ['Settings.toml', 'Projects.toml'];

/// Copies the files from [seededAppDataFileNames] that exist in [from] but not in [to], creating [to] when needed.
/// Returns the names of the copied files.
Future<List<String>> seedAppDataDirectory({required String from, required String to}) async {
  await Directory(to).create(recursive: true);

  List<String> copied = [];
  for (String fileName in seededAppDataFileNames) {
    File source = File(path.join(from, fileName));
    File target = File(path.join(to, fileName));
    if (target.existsSync() || !source.existsSync()) continue;

    await source.copy(target.path);
    copied.add(fileName);
  }
  return copied;
}
