import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:momento_booth/hardware_control/printing/print_calibration.dart';
import 'package:momento_booth/models/print_routing_graph.dart';

/// The number of pages in [pdf], from the page count in its page tree.
int _pageCount(List<int> pdf) => int.parse(RegExp(r'/Count (\d+)').firstMatch(latin1.decode(pdf))!.group(1)!);

void main() {
  final logo = File('assets/svg/logo_color.svg').readAsStringSync();

  test('renders a calibration page with the logo, the set margins and the margins of the driver', () async {
    final pdf = await renderCalibrationPdf(
      printer: const PrinterNodeData(label: 'Kodak', queueId: 'KODAK 6850', media: PrintMedia(name: '272', widthMm: 105, heightMm: 156.1), borderless: true),
      mediaLabel: '4 x 6 in',
      rulerLength: defaultCalibrationRulerLength,
      margins: const PrintMargins(top: 2, right: 1.5, bottom: 2, left: 1.5),
      driverMargins: const PrintMargins(top: 14.6, right: 8, bottom: 14.6, left: 8),
      logoSvg: logo,
      printedAt: DateTime(2026, 11, 25, 14, 30),
    );

    expect(_pageCount(pdf), 1);
  });

  test('shortens rulers that do not fit, and lays out the rest beside them on narrow media', () async {
    final pdf = await renderCalibrationPdf(
      printer: const PrinterNodeData(queueId: 'strip', media: PrintMedia(widthMm: 51, heightMm: 152)),
      mediaLabel: '2 x 6 in',
      rulerLength: 40,
      margins: const PrintMargins(),
      logoSvg: logo,
      printedAt: DateTime(2026, 11, 25),
    );

    expect(_pageCount(pdf), 1);
  });

  test('lays out the rest of the page beside the rulers on landscape media', () async {
    final pdf = await renderCalibrationPdf(
      printer: const PrinterNodeData(queueId: 'a4', media: PrintMedia(widthMm: 297, heightMm: 210)),
      mediaLabel: 'A4',
      rulerLength: defaultCalibrationRulerLength,
      margins: const PrintMargins(top: 5, right: 5, bottom: 5, left: 5),
      logoSvg: logo,
      printedAt: DateTime(2026, 11, 25),
    );

    expect(_pageCount(pdf), 1);
  });
}
