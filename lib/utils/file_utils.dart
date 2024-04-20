import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

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
