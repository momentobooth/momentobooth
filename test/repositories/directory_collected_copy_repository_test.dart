import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:momento_booth/hardware_control/printing/stack_collector.dart';
import 'package:momento_booth/models/settings.dart';
import 'package:momento_booth/repositories/collected_copies/directory_collected_copy_repository.dart';

void main() {
  group('DirectoryCollectedCopyRepository', () {
    test('keeps the list and the photos in its directory', () async {
      final directory = await Directory.systemTemp.createTemp('collected_copies_test');
      addTearDown(() => directory.delete(recursive: true));
      final repository = DirectoryCollectedCopyRepository(Directory('${directory.path}/CollectedPrints'));

      expect(await repository.load(), isEmpty);

      final collector = StackCollector(repository);
      await collector.add(stackNodeId: 'stack', jobName: 'normal', size: PrintSize.normal, image: Uint8List(1), aspectRatio: 2, count: 2);
      final reloaded = await DirectoryCollectedCopyRepository(repository.directory).load();
      expect(reloaded, collector.copies);
      expect(await repository.readImage(reloaded.first.imageFile), Uint8List(1));

      await collector.remove(collector.copies);
      expect(await repository.load(), isEmpty);
      expect(repository.directory.listSync().map((entity) => entity.uri.pathSegments.last), ['waiting.json']);
    });
  });
}
