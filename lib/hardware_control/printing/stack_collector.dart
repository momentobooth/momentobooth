import 'dart:typed_data';

import 'package:momento_booth/hardware_control/printing/print_router.dart';
import 'package:momento_booth/hardware_control/printing/print_stack_packer.dart';
import 'package:momento_booth/models/collected_copy.dart';
import 'package:momento_booth/models/settings.dart';
import 'package:momento_booth/repositories/collected_copies/collected_copy_repository.dart';
import 'package:synchronized/synchronized.dart';

/// The copies that wait on stacks in collect mode, until their sheet is printed.
///
/// Every change is saved to the [repository] right away, so the waiting copies survive a restart. Operations that read and
/// change the list together run one at a time with [locked].
class StackCollector {

  final CollectedCopyRepository repository;
  final DateTime Function() _now;
  int _lastId = 0;

  List<CollectedCopy> _copies = const [];
  Set<String> _heldIds = const {};

  /// When the first print after loading released the held copies, see [isHeld].
  DateTime? _resumedAt;
  final Lock _lock = Lock();

  StackCollector(this.repository, {DateTime Function()? now}) : _now = now ?? DateTime.now;

  /// The waiting copies, oldest first.
  List<CollectedCopy> get copies => _copies;

  /// Whether [copy] was already waiting when the list was loaded: it is from an earlier session, for example after the
  /// computer restarted or when a project is opened again days after an event. Such a copy is held until a new print
  /// is added, which resumes the event: until then it is only printed on request, see [sheets].
  bool isHeld(CollectedCopy copy) => _heldIds.contains(copy.id);

  /// The held copies that still wait, see [isHeld].
  Iterable<CollectedCopy> get heldCopies => _copies.where(isHeld);

  Future<void> load() async {
    _copies = List.unmodifiable(await repository.load());
    _heldIds = {for (final copy in _copies) copy.id};
    // New IDs continue after the ones that are waiting.
    for (final copy in _copies) {
      final id = int.tryParse(copy.printId) ?? 0;
      if (id > _lastId) _lastId = id;
    }
  }

  /// Runs [action] once the actions before it are done.
  Future<T> locked<T>(Future<T> Function() action) => _lock.synchronized(action);

  /// Adds [count] copies of [image] to stack [stackNodeId], as one print, and releases the held copies, see [isHeld].
  /// Returns the ID of the print.
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
    await repository.writeImage(imageFile, image);
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
    await repository.save(_copies);
    if (_heldIds.isNotEmpty) {
      _heldIds = const {};
      _resumedAt = now;
    }
    return printId;
  }

  /// Removes [copies], for example once their sheet is printed, and the photos no copy needs any more.
  Future<void> remove(Iterable<CollectedCopy> copies) async {
    final ids = {for (final copy in copies) copy.id};
    final removed = _copies.where((copy) => ids.contains(copy.id)).toList();
    _copies = List.unmodifiable(_copies.where((copy) => !ids.contains(copy.id)));
    await repository.save(_copies);
    final stillUsed = {for (final copy in _copies) copy.imageFile};
    for (final imageFile in {for (final copy in removed) copy.imageFile}.difference(stillUsed)) {
      await repository.deleteImage(imageFile);
    }
  }

  Future<Uint8List> readImage(CollectedCopy copy) => repository.readImage(copy.imageFile);

  /// When the last copy was added to stack [stackNodeId], or null when no copy waits on it. The copies that were held
  /// count as added when they were released, so their idle time starts again.
  DateTime? lastAddedAt(String stackNodeId) {
    for (final copy in _copies.reversed) {
      if (copy.stackNodeId != stackNodeId) continue;
      final resumedAt = _resumedAt;
      return resumedAt != null && resumedAt.isAfter(copy.addedAt) ? resumedAt : copy.addedAt;
    }
    return null;
  }

  /// The copies waiting on [stackNodeId], divided over the sheets of [route] in the order they came in. A copy is never
  /// divided over two sheets. Every sheet but the last is full; the last one is only included when it is full too, or
  /// with [includeUnfull]. Held copies are left out, unless [includeHeld], see [isHeld].
  ///
  /// The last sheet is full when no copy like the ones on it fits any more: of the same shape, and for a split print,
  /// both halves.
  List<List<CollectedCopy>> sheets(String stackNodeId, PrintRoute route, {bool includeUnfull = false, bool includeHeld = false}) {
    final List<List<CollectedCopy>> sheets = [];
    List<CollectedCopy> sheet = [];
    for (final copy in _copies.where((copy) => copy.stackNodeId == stackNodeId && (includeHeld || !isHeld(copy)))) {
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
  /// [sheets]. Null when no copy waits on the stack, apart from held ones.
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
