import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:momento_booth/hardware_control/printing/print_router.dart';
import 'package:momento_booth/hardware_control/printing/stack_collector.dart';
import 'package:momento_booth/models/collected_copy.dart';
import 'package:momento_booth/models/print_routing_graph.dart';
import 'package:momento_booth/models/settings.dart';

import 'memory_collected_copy_store.dart';

/// A stack of one column on media of 100 × 200 mm, without margins or gaps.
const _route = PrintRoute(
  printerNodeId: 'printer',
  printer: PrinterNodeData(queueId: 'printer', media: PrintMedia(widthMm: 100, heightMm: 200)),
  margins: PrintMargins(),
  stackNodeId: 'stack',
  stack: StackNodeData(mode: StackMode.collect, gap: 0),
);

// A normal copy of a 2:1 photo is 50 mm high; a split copy of a square one is two halves of 50 mm.
Future<void> _addNormal(StackCollector collector, [int count = 1]) =>
    collector.add(stackNodeId: 'stack', jobName: 'normal', size: PrintSize.normal, image: Uint8List(1), aspectRatio: 2, count: count);

Future<void> _addSplit(StackCollector collector) =>
    collector.add(stackNodeId: 'stack', jobName: 'split', size: PrintSize.split, image: Uint8List(1), aspectRatio: 1, count: 1);

List<List<String>> _jobs(List<List<CollectedCopy>> sheets) => [
  for (final sheet in sheets) [for (final copy in sheet) copy.jobName],
];

void main() {
  group('StackCollector.sheets', () {
    test('keeps a sheet waiting while a copy like one on it still fits', () async {
      final collector = StackCollector(MemoryCollectedCopyStore());
      await _addNormal(collector);
      await _addSplit(collector);

      // 150 of 200 mm used: another split does not fit, but another normal copy does.
      expect(collector.sheets('stack', _route), isEmpty);
      expect(_jobs(collector.sheets('stack', _route, includeUnfull: true)), [['normal', 'split']]);

      await _addNormal(collector);
      expect(_jobs(collector.sheets('stack', _route)), [['normal', 'split', 'normal']]);
    });

    test('never divides a copy over two sheets', () async {
      final collector = StackCollector(MemoryCollectedCopyStore());
      await _addNormal(collector, 3);
      await _addSplit(collector);

      // The split does not fit in the last 50 mm, so it starts a sheet, which is not full yet.
      expect(_jobs(collector.sheets('stack', _route)), [['normal', 'normal', 'normal']]);
      expect(_jobs(collector.sheets('stack', _route, includeUnfull: true)), [['normal', 'normal', 'normal'], ['split']]);
    });

    test('only takes the copies of the stack', () async {
      final collector = StackCollector(MemoryCollectedCopyStore());
      await collector.add(stackNodeId: 'other', jobName: 'other', size: PrintSize.normal, image: Uint8List(1), aspectRatio: 2, count: 4);

      expect(collector.sheets('stack', _route, includeUnfull: true), isEmpty);
    });
  });

  group('StackCollector', () {
    test('saves every change, and keeps a photo until no copy needs it', () async {
      final store = MemoryCollectedCopyStore();
      final collector = StackCollector(store);
      await collector.add(stackNodeId: 'stack', jobName: 'job', size: PrintSize.normal, image: Uint8List.fromList([0xFF, 0xD8, 1]), aspectRatio: 2, count: 2);

      expect(store.saved, hasLength(2));
      expect(store.images.keys.single, endsWith('.jpg'));

      await collector.remove([collector.copies.first]);
      expect(store.saved, hasLength(1));
      expect(store.images, hasLength(1));

      await collector.remove(collector.copies);
      expect(store.saved, isEmpty);
      expect(store.images, isEmpty);
    });

    test('loads the copies that were waiting, with unique IDs for new ones', () async {
      final store = MemoryCollectedCopyStore();
      final now = DateTime(2026, 11, 23, 12);
      await _addNormal(StackCollector(store, now: () => now), 2);

      final restarted = StackCollector(store, now: () => now);
      await restarted.load();
      expect(restarted.copies, hasLength(2));

      await _addNormal(restarted);
      expect({for (final copy in restarted.copies) copy.id}, hasLength(3));
    });

    test('runs locked actions one at a time', () async {
      final collector = StackCollector(MemoryCollectedCopyStore());
      final List<String> order = [];
      final first = collector.locked(() async {
        order.add('first starts');
        await Future<void>.delayed(const Duration(milliseconds: 10));
        order.add('first ends');
      });
      final second = collector.locked(() async => order.add('second'));
      await Future.wait([first, second]);

      expect(order, ['first starts', 'first ends', 'second']);
    });
  });

  group('DirectoryCollectedCopyStore', () {
    test('keeps the list and the photos in its directory', () async {
      final directory = await Directory.systemTemp.createTemp('collected_copies_test');
      addTearDown(() => directory.delete(recursive: true));
      final store = DirectoryCollectedCopyStore(Directory('${directory.path}/CollectedPrints'));

      expect(await store.load(), isEmpty);

      final collector = StackCollector(store);
      await _addNormal(collector, 2);
      final reloaded = await DirectoryCollectedCopyStore(store.directory).load();
      expect(reloaded, collector.copies);
      expect(await store.readImage(reloaded.first.imageFile), Uint8List(1));

      await collector.remove(collector.copies);
      expect(await store.load(), isEmpty);
      expect(store.directory.listSync().map((entity) => entity.uri.pathSegments.last), ['waiting.json']);
    });
  });
}
