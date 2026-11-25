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

/// A copy to put on a stack: a photo, or both its halves for a split print. The photo has a [bleed] on every side, as
/// a fraction of its height, see [renderPrintPdf].
class StackedCopy {

  final Uint8List image;
  final bool split;
  final double bleed;

  const StackedCopy(this.image, {required this.split, this.bleed = 0});

}

/// Which part of a photo an item of a stack shows.
enum _StackItemPart { whole, leftHalf, rightHalf }

/// Renders [copies] stacked on the media of [route], see [packStackOn]. Every sheet the copies fill is a page. The
/// halves of a split print are stacked as separate items.
///
/// Every item fills its place without its bleed. The bleed shows up to half the gap of the stack around it, and on
/// borderless media beyond the edges of the viewport the item reaches, see [stackItemVisibleRect].
Future<Uint8List> renderStackPdf(List<StackedCopy> copies, PrintRoute route) {
  const mm = PdfPageFormat.mm;
  final doc = pw.Document(title: "MomentoBooth image");
  final mmViewport = stackViewport(route);
  final viewport = PageRect(mmViewport.left * mm, mmViewport.top * mm, mmViewport.width * mm, mmViewport.height * mm);

  // Every distinct photo is embedded once.
  final Map<Uint8List, pw.MemoryImage> photos = {};
  final List<(pw.MemoryImage photo, double bleed, _StackItemPart part)> items = [];
  final List<double> aspectRatios = [];
  for (final copy in copies) {
    final photo = photos[copy.image] ??= pw.MemoryImage(copy.image);
    final aspectRatio = photo.width! / photo.height!;
    if (copy.split) {
      items.addAll([(photo, copy.bleed, _StackItemPart.leftHalf), (photo, copy.bleed, _StackItemPart.rightHalf)]);
    } else {
      items.add((photo, copy.bleed, _StackItemPart.whole));
    }
    aspectRatios.addAll(stackItemsOf(aspectRatio, split: copy.split, bleed: copy.bleed));
  }
  final sheets = packStackOn(route, aspectRatios, unit: mm);

  for (final sheet in sheets) {
    doc.addPage(_positionedPage(route, [
      for (final placement in sheet)
        _stackItem(items[placement.item], placement, gap: route.stack!.gap * mm, viewport: viewport, borderless: route.printer.borderless),
    ]));
  }
  return doc.save();
}

/// An item of a stack at [placement], with as much of its bleed as [stackItemVisibleRect] allows.
pw.Widget _stackItem(
  (pw.MemoryImage, double, _StackItemPart) item,
  StackPlacement placement, {
  required double gap,
  required PageRect viewport,
  required bool borderless,
}) {
  final (photo, bleed, part) = item;
  // The item without its bleed, in the photo's own orientation.
  final width = placement.turned ? placement.height : placement.width;
  final height = placement.turned ? placement.width : placement.height;
  // The whole photo, as drawn, and its bleed.
  final photoHeight = height / (1 - 2 * bleed);
  final photoWidth = photoHeight * photo.width! / photo.height!;
  final bleedSize = bleed * photoHeight;

  // The item with its bleed on every side, laid out in the photo's own orientation and turned as a whole. A half has
  // no bleed where the halves meet, so that side stays empty: then the item is centred on its place either way it is
  // turned.
  final pw.Widget withBleed = pw.SizedBox(
    width: width + 2 * bleedSize,
    height: height + 2 * bleedSize,
    child: pw.Stack(
      children: [
        // The part of the photo to show, its bleed included. For the right half, that starts in the middle of the photo.
        pw.Positioned(
          left: part == _StackItemPart.rightHalf ? bleedSize : 0,
          top: 0,
          child: pw.SizedBox(
            width: part == _StackItemPart.whole ? width + 2 * bleedSize : width + bleedSize,
            height: height + 2 * bleedSize,
            child: pw.Stack(
              children: [
                pw.Positioned(
                  left: part == _StackItemPart.rightHalf ? -photoWidth / 2 : 0,
                  top: 0,
                  child: pw.Image(photo, fit: pw.BoxFit.fill, width: photoWidth, height: photoHeight),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );

  final visible = stackItemVisibleRect(placement, bleedSize: bleedSize, gap: gap, viewport: viewport, borderless: borderless);
  // The pdf Stack clips what lies beyond it, which limits the item to its visible part.
  return pw.Positioned(
    left: visible.left,
    top: visible.top,
    child: pw.SizedBox(
      width: visible.width,
      height: visible.height,
      child: pw.Stack(
        children: [
          pw.Positioned(
            left: placement.left - bleedSize - visible.left,
            top: placement.top - bleedSize - visible.top,
            child: placement.turned ? pw.Transform.rotateBox(angle: 0.5 * pi, child: withBleed) : withBleed,
          ),
        ],
      ),
    ),
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
