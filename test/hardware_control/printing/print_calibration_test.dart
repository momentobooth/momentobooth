import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:momento_booth/hardware_control/printing/print_calibration.dart';
import 'package:momento_booth/models/print_routing_graph.dart';

/// The number of pages in [pdf], from the page count in its page tree.
int _pageCount(List<int> pdf) => int.parse(RegExp(r'/Count (\d+)').firstMatch(latin1.decode(pdf))!.group(1)!);

void main() {
  final logo = File('assets/svg/logo.svg').readAsStringSync();

  test('renders a calibration page with the logo and the margins of the driver', () async {
    final pdf = await renderCalibrationPdf(
      printer: const PrinterNodeData(label: 'Kodak', queueId: 'KODAK 6850', media: PrintMedia(name: '272', widthMm: 105, heightMm: 156.1), borderless: true),
      mediaLabel: '4 x 6 in',
      rulerLength: defaultCalibrationRulerLength,
      driverMargins: const PrintMargins(top: 14.6, right: 8, bottom: 14.6, left: 8),
      logoSvg: logo,
      printedAt: DateTime(2026, 11, 25, 14, 30),
    );

    expect(_pageCount(pdf), 1);
  });

  test('shortens rulers that do not fit, and shrinks the rest of the page', () async {
    final pdf = await renderCalibrationPdf(
      printer: const PrinterNodeData(queueId: 'strip', media: PrintMedia(widthMm: 51, heightMm: 152)),
      mediaLabel: '2 x 6 in',
      rulerLength: 40,
      logoSvg: logo,
      printedAt: DateTime(2026, 11, 25),
    );

    expect(_pageCount(pdf), 1);
  });
}
