import 'dart:typed_data';

import 'package:momento_booth/models/collected_copy.dart';

/// Where the copies that wait on stacks are kept: the list, and a file per photo.
abstract interface class CollectedCopyRepository {

  Future<List<CollectedCopy>> load();

  Future<void> save(List<CollectedCopy> copies);

  Future<void> writeImage(String name, Uint8List image);

  Future<Uint8List> readImage(String name);

  /// Does nothing when the image does not exist.
  Future<void> deleteImage(String name);

}
