import 'dart:math';
import 'dart:typed_data';

import 'package:momento_booth/hardware_control/printing/print_router.dart';
import 'package:momento_booth/hardware_control/printing/print_stack_packer.dart';
import 'package:momento_booth/models/print_routing_graph.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Renders [image] on the media of [route], within its margins.
///
/// The photo is turned to match the orientation of the space it gets. Split prints, the halves of a wide collage, are
/// rendered as two pages that each show one half.
Future<Uint8List> renderPrintPdf(Uint8List image, PrintRoute route, {required bool split}) {
  final photo = pw.MemoryImage(image);
  final doc = pw.Document(title: "MomentoBooth image");
  final layout = route.layout;

  if (split) {
    _addSplitPages(doc, photo, route);
  } else if (layout != null) {
    _addTiledPage(doc, photo, _pageFormat(route), layout);
  } else {
    _addFittedPage(doc, photo, _pageFormat(route));
  }
  return doc.save();
}

/// Renders [copies] copies of [image] stacked on the media of [route], within its margins, see [packStack]. Every
/// sheet the copies fill is a page. The halves of a split print are stacked as separate items.
Future<Uint8List> renderStackPdf(Uint8List image, PrintRoute route, {required int copies, required bool split}) {
  final stack = route.stack!;
  final photo = pw.MemoryImage(image);
  final doc = pw.Document(title: "MomentoBooth image");
  final format = _pageFormat(route);

  final List<pw.Alignment?> items = [
    for (int copy = 0; copy < copies; copy++)
      if (split) ...const [pw.Alignment.centerLeft, pw.Alignment.centerRight] else null,
  ];
  final photoAspectRatio = photo.width! / photo.height!;
  final sheets = packStack(
    [
      for (final half in items)
        if (half == null) photoAspectRatio else photoAspectRatio / 2,
    ],
    width: format.availableWidth,
    height: format.availableHeight,
    lanes: stack.lanes,
    rows: stack.direction == StackDirection.rows,
    gap: stack.gap * PdfPageFormat.mm,
  );

  for (final sheet in sheets) {
    doc.addPage(pw.Page(
      pageFormat: format,
      build: (_) => pw.Align(
        alignment: pw.Alignment.topLeft,
        child: pw.SizedBox(
          width: format.availableWidth,
          height: format.availableHeight,
          child: pw.Stack(
            children: [
              for (final placement in sheet)
                pw.Positioned(
                  left: placement.left,
                  top: placement.top,
                  child: switch (items[placement.item]) {
                    null => _fittedPhoto(photo, placement.width, placement.height),
                    final half => _halfPhoto(photo, half, placement),
                  },
                ),
            ],
          ),
        ),
      ),
    ));
  }
  return doc.save();
}

/// The half of the photo at [half] (left or right), filling [placement].
pw.Widget _halfPhoto(pw.MemoryImage photo, pw.Alignment half, StackPlacement placement) {
  // Laid out in the photo's own orientation, and turned as a whole.
  final width = placement.turned ? placement.height : placement.width;
  final height = placement.turned ? placement.width : placement.height;
  final pw.Widget part = pw.SizedBox(
    width: width,
    height: height,
    child: pw.ClipRect(
      child: pw.Image(photo, fit: pw.BoxFit.fitHeight, width: width, height: height, alignment: half),
    ),
  );
  return placement.turned ? pw.Transform.rotateBox(angle: 0.5 * pi, child: part) : part;
}

PdfPageFormat _pageFormat(PrintRoute route, {bool leftMargin = true, bool rightMargin = true}) {
  const mm = PdfPageFormat.mm;
  final media = route.printer.media;
  final margins = route.margins;
  return PdfPageFormat(
    media.widthMm * mm,
    media.heightMm * mm,
    marginTop: margins.top * mm,
    marginRight: rightMargin ? margins.right * mm : 0,
    marginBottom: margins.bottom * mm,
    marginLeft: leftMargin ? margins.left * mm : 0,
  );
}

bool _isLandscape(double width, double height) => width > height;

/// The photo, fitted in a box of [width] by [height] and turned a quarter when that fits its orientation better.
pw.Widget _fittedPhoto(pw.MemoryImage photo, double width, double height) {
  final bool turn = _isLandscape(photo.width!.toDouble(), photo.height!.toDouble()) != _isLandscape(width, height);
  // When turned, the size must be given in the photo's own orientation, or it ends up too small.
  return turn
      ? pw.Transform.rotateBox(angle: 0.5 * pi, child: pw.Image(photo, fit: pw.BoxFit.contain, width: height, height: width))
      : pw.Image(photo, fit: pw.BoxFit.contain, width: width, height: height);
}

void _addFittedPage(pw.Document doc, pw.MemoryImage photo, PdfPageFormat format) {
  doc.addPage(pw.Page(
    pageFormat: format,
    build: (_) => pw.Center(child: _fittedPhoto(photo, format.availableWidth, format.availableHeight)),
  ));
}

void _addTiledPage(pw.Document doc, pw.MemoryImage photo, PdfPageFormat format, TileLayoutNodeData layout) {
  final cellWidth = format.availableWidth / layout.columns;
  final cellHeight = format.availableHeight / layout.rows;
  final cell = pw.Center(child: _fittedPhoto(photo, cellWidth, cellHeight));

  doc.addPage(pw.Page(
    pageFormat: format,
    build: (_) => pw.Column(
      children: [
        for (int row = 0; row < layout.rows; row++)
          pw.SizedBox(
            height: cellHeight,
            child: pw.Row(
              children: [
                for (int column = 0; column < layout.columns; column++) pw.SizedBox(width: cellWidth, child: cell),
              ],
            ),
          ),
      ],
    ),
  ));
}

/// Two pages that together show the photo: the left half on the first, the right half on the second. The margins
/// between the halves are left out, so the photo continues where the pages are put together.
void _addSplitPages(pw.Document doc, pw.MemoryImage photo, PrintRoute route) {
  for (final alignment in [pw.Alignment.centerLeft, pw.Alignment.centerRight]) {
    final bool left = alignment == pw.Alignment.centerLeft;
    final format = _pageFormat(route, leftMargin: left, rightMargin: !left);
    doc.addPage(pw.Page(
      pageFormat: format,
      build: (_) => pw.Center(
        child: pw.Image(
          photo,
          fit: pw.BoxFit.fitHeight,
          width: format.availableWidth,
          height: format.availableHeight,
          alignment: alignment,
        ),
      ),
    ));
  }
}
