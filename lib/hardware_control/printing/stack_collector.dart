import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:momento_booth/hardware_control/printing/print_router.dart';
import 'package:momento_booth/hardware_control/printing/print_stack_packer.dart';
import 'package:momento_booth/models/collected_copy.dart';
import 'package:momento_booth/models/settings.dart';
import 'package:path/path.dart' as path;

/// Where the copies that wait on stacks are kept: the list, and a file per photo.
abstract interface class CollectedCopyStore {

  Future<List<CollectedCopy>> load();

  Future<void> save(List<CollectedCopy> copies);

  Future<void> writeImage(String name, Uint8List image);

  Future<Uint8List> readImage(String name);

  /// Does nothing when the image does not exist.
  Future<void> deleteImage(String name);

}

/// Keeps the waiting copies in [directory]: the list in `waiting.json`, and the photos next to it.
class DirectoryCollectedCopyStore implements CollectedCopyStore {

  final Directory directory;

  const DirectoryCollectedCopyStore(this.directory);

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

/// The copies that wait on stacks in collect mode, until their sheet is printed.
///
/// Every change is saved to the [store] right away, so the waiting copies survive a restart. Operations that read and
/// change the list together run one at a time with [locked].
class StackCollector {

  final CollectedCopyStore store;
  final DateTime Function() _now;
  int _lastId = 0;

  List<CollectedCopy> _copies = const [];
  Future<void> _tail = Future.value();

  StackCollector(this.store, {DateTime Function()? now}) : _now = now ?? DateTime.now;

  /// The waiting copies, oldest first.
  List<CollectedCopy> get copies => _copies;

  Future<void> load() async {
    _copies = List.unmodifiable(await store.load());
    // New IDs continue after the ones that are waiting.
    for (final copy in _copies) {
      final id = int.tryParse(copy.printId) ?? 0;
      if (id > _lastId) _lastId = id;
    }
  }

  /// Runs [action] once the actions before it are done.
  Future<T> locked<T>(Future<T> Function() action) {
    final result = _tail.then((_) => action());
    _tail = result.then((_) {}, onError: (_) {});
    return result;
  }

  /// Adds [count] copies of [image] to stack [stackNodeId], as one print. Returns the ID of the print.
  Future<String> add({
    required String stackNodeId,
    required String jobName,
    required PrintSize size,
    required Uint8List image,
    required double aspectRatio,
    required int count,
  }) async {
    final now = _now();
    final printId = _newId(now);
    final imageFile = '$printId${_extensionOf(image)}';
    await store.writeImage(imageFile, image);
    _copies = List.unmodifiable([
      ..._copies,
      for (int copy = 1; copy <= count; copy++)
        CollectedCopy(
          id: '$printId-$copy',
          printId: printId,
          jobName: jobName,
          stackNodeId: stackNodeId,
          size: size,
          imageFile: imageFile,
          aspectRatio: aspectRatio,
          addedAt: now,
        ),
    ]);
    await store.save(_copies);
    return printId;
  }

  /// Removes [copies], for example once their sheet is printed, and the photos no copy needs any more.
  Future<void> remove(Iterable<CollectedCopy> copies) async {
    final ids = {for (final copy in copies) copy.id};
    final removed = _copies.where((copy) => ids.contains(copy.id)).toList();
    _copies = List.unmodifiable(_copies.where((copy) => !ids.contains(copy.id)));
    await store.save(_copies);
    final stillUsed = {for (final copy in _copies) copy.imageFile};
    for (final imageFile in {for (final copy in removed) copy.imageFile}.difference(stillUsed)) {
      await store.deleteImage(imageFile);
    }
  }

  Future<Uint8List> readImage(CollectedCopy copy) => store.readImage(copy.imageFile);

  /// When the last copy was added to stack [stackNodeId], or null when no copy waits on it.
  DateTime? lastAddedAt(String stackNodeId) {
    for (final copy in _copies.reversed) {
      if (copy.stackNodeId == stackNodeId) return copy.addedAt;
    }
    return null;
  }

  /// The copies waiting on [stackNodeId], divided over the sheets of [route] in the order they came in. A copy is never
  /// divided over two sheets. Every sheet but the last is full; the last one is only included when it is full too, or
  /// with [includeUnfull].
  ///
  /// The last sheet is full when no copy like the ones on it fits any more: of the same shape, and for a split print,
  /// both halves.
  List<List<CollectedCopy>> sheets(String stackNodeId, PrintRoute route, {bool includeUnfull = false}) {
    final List<List<CollectedCopy>> sheets = [];
    List<CollectedCopy> sheet = [];
    for (final copy in _copies.where((copy) => copy.stackNodeId == stackNodeId)) {
      if (sheet.isNotEmpty && !_fitsOnOneSheet(route, [...sheet.map(_shapeOf), _shapeOf(copy)])) {
        sheets.add(sheet);
        sheet = [];
      }
      sheet.add(copy);
    }
    if (sheet.isEmpty) return sheets;

    final shapes = sheet.map(_shapeOf).toList();
    final bool full = shapes.toSet().every((shape) => !_fitsOnOneSheet(route, [...shapes, shape]));
    if (full || includeUnfull) sheets.add(sheet);
    return sheets;
  }

  /// How far the last sheet of [stackNodeId] is on its way to full, from 0 to 1: the copies on it, divided by those
  /// copies plus the most copies of one shape on it that still fit. So it is 1 exactly when the sheet is full, see
  /// [sheets]. Null when no copy waits on the stack.
  double? fillOfLastSheet(String stackNodeId, PrintRoute route) {
    final sheet = sheets(stackNodeId, route, includeUnfull: true).lastOrNull;
    if (sheet == null) return null;
    final shapes = sheet.map(_shapeOf).toList();
    int mostMore = 0;
    for (final shape in shapes.toSet()) {
      int more = 0;
      // Every copy takes room, so this ends; the limit only guards against a packer that would think otherwise.
      while (more < 1000 && _fitsOnOneSheet(route, [...shapes, for (int i = 0; i <= more; i++) shape])) {
        more++;
      }
      if (more > mostMore) mostMore = more;
    }
    return shapes.length / (shapes.length + mostMore);
  }

  static bool _fitsOnOneSheet(PrintRoute route, Iterable<(double, bool)> shapes) => packStackOn(route, [
    for (final (aspectRatio, split) in shapes) ...stackItemsOf(aspectRatio, split: split),
  ]).length <= 1;

  /// What decides the room a copy takes on a stack: its aspect ratio, and whether it is printed in halves.
  static (double, bool) _shapeOf(CollectedCopy copy) => (copy.aspectRatio, copy.size == PrintSize.split);

  String _newId(DateTime now) {
    // Unique within this list, also for prints added in the same microsecond.
    final id = now.microsecondsSinceEpoch;
    _lastId = id > _lastId ? id : _lastId + 1;
    return '$_lastId';
  }

  static String _extensionOf(Uint8List image) => switch (image) {
    [0xFF, 0xD8, ...] => '.jpg',
    [0x89, 0x50, 0x4E, 0x47, ...] => '.png',
    _ => '.img',
  };

}
