import 'dart:io';
import 'dart:typed_data';

import 'package:momento_booth/models/collected_copy.dart';
import 'package:momento_booth/repositories/collected_copies/collected_copy_repository.dart';

/// Keeps the waiting list in memory.
class MemoryCollectedCopyRepository implements CollectedCopyRepository {

  List<CollectedCopy> saved = [];
  final Map<String, Uint8List> images = {};

  @override
  Future<List<CollectedCopy>> load() async => saved;

  @override
  Future<void> save(List<CollectedCopy> copies) async => saved = [...copies];

  @override
  Future<void> writeImage(String name, Uint8List image) async => images[name] = image;

  @override
  Future<Uint8List> readImage(String name) async => images[name] ?? (throw FileSystemException('No image', name));

  @override
  Future<void> deleteImage(String name) async => images.remove(name);

}
