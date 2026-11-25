import 'dart:math';
import 'dart:typed_data';

import 'package:momento_booth/hardware_control/printing/photo_placement.dart';
import 'package:momento_booth/hardware_control/printing/print_router.dart';
import 'package:momento_booth/hardware_control/printing/print_stack_packer.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Renders [image] on the media of [route], within the viewport its margins leave.
///
/// The photo is turned to match the orientation of the space it gets. Split prints, the halves of a wide collage, are
/// rendered as two pages that each show one half.
///
/// The photo has a [bleed] on every side, as a fraction of its height (the collage padding). On borderless media, the
/// bleed lies beyond the edges of the viewport the photo reaches, so the printer cuts it off. Elsewhere, and on media
/// with a border, the bleed stays inside the viewport, to be cut off by hand. See [placePhoto].
Future<Uint8List> renderPrintPdf(Uint8List image, PrintRoute route, {required bool split, double bleed = 0}) {
  final photo = pw.MemoryImage(image);
  final doc = pw.Document(title: "MomentoBooth image");
  final layout = route.layout;

  if (split) {
    _addSplitPages(doc, photo, route, bleed);
  } else {
    _addPhotoPage(doc, photo, route, bleed, rows: layout?.rows ?? 1, columns: layout?.columns ?? 1);
  }
  return doc.save();
}

/// The width of [image] divided by its height.
double photoAspectRatio(Uint8List image) {
  final photo = pw.MemoryImage(image);
  return photo.width! / photo.height!;
}

/// A copy to put on a stack: a photo, or both its halves for a split print.
class StackedCopy {

  final Uint8List image;
  final bool split;

  const StackedCopy(this.image, {required this.split});

}

/// Renders [copies] stacked on the media of [route], within its margins, see [packStack]. Every sheet the copies fill
/// is a page. The halves of a split print are stacked as separate items.
Future<Uint8List> renderStackPdf(List<StackedCopy> copies, PrintRoute route) {
  final doc = pw.Document(title: "MomentoBooth image");
  final format = _pageFormat(route);

  // Every distinct photo is embedded once.
  final Map<Uint8List, pw.MemoryImage> photos = {};
  final List<(pw.MemoryImage photo, pw.Alignment? half)> items = [];
  final List<double> aspectRatios = [];
  for (final copy in copies) {
    final photo = photos[copy.image] ??= pw.MemoryImage(copy.image);
    final aspectRatio = photo.width! / photo.height!;
    if (copy.split) {
      items.addAll([(photo, pw.Alignment.centerLeft), (photo, pw.Alignment.centerRight)]);
    } else {
      items.add((photo, null));
    }
    aspectRatios.addAll(stackItemsOf(aspectRatio, split: copy.split));
  }
  final sheets = packStackOn(route, aspectRatios, unit: PdfPageFormat.mm);

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
                    (final photo, null) => _fittedPhoto(photo, placement.width, placement.height),
                    (final photo, final half?) => _halfPhoto(photo, half, placement),
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

PdfPageFormat _pageFormat(PrintRoute route) {
  const mm = PdfPageFormat.mm;
  final media = route.printer.media;
  final margins = route.margins;
  return PdfPageFormat(
    media.widthMm * mm,
    media.heightMm * mm,
    marginTop: margins.top * mm,
    marginRight: margins.right * mm,
    marginBottom: margins.bottom * mm,
    marginLeft: margins.left * mm,
  );
}

/// The part of the page that ends up visible on the print, in points: the media minus the margins.
PageRect _viewport(PrintRoute route) {
  const mm = PdfPageFormat.mm;
  final media = route.printer.media;
  final margins = route.margins;
  return PageRect(
    margins.left * mm,
    margins.top * mm,
    (media.widthMm - margins.left - margins.right) * mm,
    (media.heightMm - margins.top - margins.bottom) * mm,
  );
}

/// A page of the media of [route] that shows [children], positioned on the whole page. What lies beyond the page is
/// left out.
pw.Page _positionedPage(PrintRoute route, List<pw.Widget> children) {
  const mm = PdfPageFormat.mm;
  final media = route.printer.media;
  final format = PdfPageFormat(media.widthMm * mm, media.heightMm * mm);
  return pw.Page(
    pageFormat: format,
    build: (_) => pw.SizedBox(width: format.width, height: format.height, child: pw.Stack(children: children)),
  );
}

/// The photo at [placement], turned when the placement says so.
pw.Widget _placedPhoto(pw.MemoryImage photo, PhotoPlacement placement) {
  final rect = placement.rect;
  // When turned, the size must be given in the photo's own orientation.
  return pw.Positioned(
    left: rect.left,
    top: rect.top,
    child: placement.turned
        ? pw.Transform.rotateBox(angle: 0.5 * pi, child: pw.Image(photo, fit: pw.BoxFit.fill, width: rect.height, height: rect.width))
        : pw.Image(photo, fit: pw.BoxFit.fill, width: rect.width, height: rect.height),
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

/// A page with the photo in every cell of a grid of [rows] by [columns] that fills the viewport. Without a tile
/// layout, the grid is a single cell. On borderless media, the cells on the edge of the grid are cut by the printer on
/// that edge.
void _addPhotoPage(pw.Document doc, pw.MemoryImage photo, PrintRoute route, double bleed, {required int rows, required int columns}) {
  final viewport = _viewport(route);
  final cellWidth = viewport.width / columns;
  final cellHeight = viewport.height / rows;
  final aspectRatio = photo.width! / photo.height!;

  doc.addPage(_positionedPage(route, [
    for (int row = 0; row < rows; row++)
      for (int column = 0; column < columns; column++)
        _placedPhoto(
          photo,
          placePhoto(
            PageRect(viewport.left + column * cellWidth, viewport.top + row * cellHeight, cellWidth, cellHeight),
            aspectRatio: aspectRatio,
            bleed: bleed,
            cut: route.printer.borderless
                ? CutSides.ofCell(row: row, column: column, rows: rows, columns: columns)
                : CutSides.none,
          ),
        ),
  ]));
}

/// Two pages that together show the photo: the left half on the first, the right half on the second. Each half fills
/// the height of the viewport. The margins between the halves are left out, so the photo continues where the pages are
/// put together.
///
/// On borderless media, the bleed lies beyond the top, bottom and outer edge of the viewport, so the printer cuts it
/// off.
void _addSplitPages(pw.Document doc, pw.MemoryImage photo, PrintRoute route, double bleed) {
  final viewport = _viewport(route);
  final cut = route.printer.borderless;
  final height = viewport.height / (cut ? 1 - 2 * bleed : 1);
  final width = height * photo.width! / photo.height!;
  final bleedSize = cut ? bleed * height : 0.0;

  for (final left in [true, false]) {
    doc.addPage(_positionedPage(route, [
      pw.Positioned(
        left: left ? viewport.left - bleedSize : viewport.right + bleedSize - width,
        top: viewport.top - bleedSize,
        child: pw.Image(photo, fit: pw.BoxFit.fill, width: width, height: height),
      ),
    ]));
  }
}
