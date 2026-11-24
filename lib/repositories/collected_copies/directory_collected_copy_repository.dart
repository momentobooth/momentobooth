import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:momento_booth/models/collected_copy.dart';
import 'package:momento_booth/repositories/collected_copies/collected_copy_repository.dart';
import 'package:path/path.dart' as path;

/// Keeps the waiting copies in [directory]: the list in `waiting.json`, and the photos next to it.
class DirectoryCollectedCopyRepository implements CollectedCopyRepository {

  final Directory directory;

  const DirectoryCollectedCopyRepository(this.directory);

  File get _listFile => File(path.join(directory.path, 'waiting.json'));

  @override
  Future<List<CollectedCopy>> load() async {
    if (!_listFile.existsSync()) return const [];
    final json = jsonDecode(await _listFile.readAsString()) as Map<String, dynamic>;
    return [
      for (final copy in json['copies'] as List<dynamic>) CollectedCopy.fromJson(copy as Map<String, Object?>),
    ];
  }

  @override
  Future<void> save(List<CollectedCopy> copies) async {
    await directory.create(recursive: true);
    // Written next to the list and then moved over it, so a crash never leaves half a list.
    final temporary = File('${_listFile.path}.tmp');
    await temporary.writeAsString(jsonEncode({'copies': [for (final copy in copies) copy.toJson()]}), flush: true);
    await temporary.rename(_listFile.path);
  }

  @override
  Future<void> writeImage(String name, Uint8List image) async {
    await directory.create(recursive: true);
    await File(path.join(directory.path, name)).writeAsBytes(image, flush: true);
  }

  @override
  Future<Uint8List> readImage(String name) => File(path.join(directory.path, name)).readAsBytes();

  @override
  Future<void> deleteImage(String name) async {
    final file = File(path.join(directory.path, name));
    if (file.existsSync()) await file.delete();
  }

}
