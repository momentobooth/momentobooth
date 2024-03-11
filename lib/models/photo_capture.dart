import 'dart:typed_data';

import 'package:freezed_annotation/freezed_annotation.dart';

part 'photo_capture.freezed.dart';

@freezed
abstract class PhotoCapture with _$PhotoCapture {

  const factory PhotoCapture({
    required String filename,
    required Uint8List data,
  }) = _PhotoCapture;

}
