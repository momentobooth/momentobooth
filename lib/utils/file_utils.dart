import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:momento_booth/main.dart';
import 'package:talker/talker.dart';

Future<File> writeBytesToFileLocked(String path, Uint8List data) async {
  File file = File(path);
  RandomAccessFile raFile = await file.open(mode: FileMode.writeOnly);

  try {
    await raFile.lock();
    await raFile.writeFrom(data);
  } finally {
    await raFile.close();
  }

  return file;
}

Future<File> writeStringFileLocked(String path, String data) {
  Uint8List bytes = const Utf8Encoder().convert(data);
  return writeBytesToFileLocked(path, bytes);
}

Future<void> createPathSafe(String path) async {
  try {
    await Directory(path).create(recursive: true);
  } catch (s) {
    getIt<Talker>().warning("Could not create path [$path]: $s");
  }
}
