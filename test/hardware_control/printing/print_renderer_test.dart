import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:momento_booth/hardware_control/printing/print_renderer.dart';
import 'package:momento_booth/hardware_control/printing/print_router.dart';
import 'package:momento_booth/models/print_routing_graph.dart';

/// A PNG of one pixel.
final _photo = base64Decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==');

const _printer = PrinterNodeData(queueId: 'printer', media: PrintMedia(widthMm: 100, heightMm: 148));

/// The number of pages in [pdf], from the page count in its page tree.
int _pageCount(List<int> pdf) => int.parse(RegExp(r'/Count (\d+)').firstMatch(latin1.decode(pdf))!.group(1)!);

void main() {
  group('renderPrintPdf', () {
    test('fits the photo on a single page', () async {
      const route = PrintRoute(printerNodeId: 'printer', printer: _printer, margins: PrintMargins(top: 2, left: 2));

      expect(_pageCount(await renderPrintPdf(_photo, route, split: false)), 1);
    });

    test('tiles the photo on a single page', () async {
      const route = PrintRoute(
        printerNodeId: 'printer',
        printer: _printer,
        margins: PrintMargins(),
        layout: TileLayoutNodeData(columns: 2, rows: 2, rotate: true),
      );

      expect(_pageCount(await renderPrintPdf(_photo, route, split: false)), 1);
    });

    test('renders a split print as two pages', () async {
      const route = PrintRoute(printerNodeId: 'printer', printer: _printer, margins: PrintMargins(left: 1, right: 1));

      expect(_pageCount(await renderPrintPdf(_photo, route, split: true)), 2);
    });
  });
}
