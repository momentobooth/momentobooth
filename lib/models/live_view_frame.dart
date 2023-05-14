import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:momento_booth/utils/image.dart';

class LiveViewFrame {

  final Uint8List rawRgbaData;
  final int width;
  final int height;

  const LiveViewFrame({
    required this.rawRgbaData,
    required this.width,
    required this.height,
  });

  Future<ui.Image> toImage() async {
    return fromUint8ListRgba(width, height, rawRgbaData);
  }

}
