import 'package:flutter/foundation.dart';
import 'package:momento_booth/hardware_control/printing/print_router.dart';
import 'package:momento_booth/models/print_routing_graph.dart';

/// Where an item of a stack ends up on a sheet. Lengths are in the units of the area the items were packed in,
/// measured from its top left corner.
@immutable
class StackPlacement {

  /// The index of the item in the list that was packed.
  final int item;

  final double left;
  final double top;
  final double width;
  final double height;

  /// Whether the item is turned a quarter, so its own width runs along [height].
  final bool turned;

  const StackPlacement({
    required this.item,
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    required this.turned,
  });

  @override
  bool operator ==(Object other) =>
      other is StackPlacement &&
      other.item == item &&
      other.left == left &&
      other.top == top &&
      other.width == width &&
      other.height == height &&
      other.turned == turned;

  @override
  int get hashCode => Object.hash(item, left, top, width, height, turned);

  @override
  String toString() => 'StackPlacement($item, $left, $top, ${width}x$height${turned ? ', turned' : ''})';

}

/// The aspect ratios of the items a copy of a photo with [aspectRatio] takes on a stack: the photo, or its two halves
/// for a split print.
List<double> stackItemsOf(double aspectRatio, {required bool split}) =>
    split ? [aspectRatio / 2, aspectRatio / 2] : [aspectRatio];

/// Packs items with [aspectRatios] on the printable area of [route] with the settings of its stack, see [packStack].
/// Lengths are in mm, times [unit].
List<List<StackPlacement>> packStackOn(PrintRoute route, List<double> aspectRatios, {double unit = 1}) {
  final stack = route.stack!;
  final media = route.printer.media;
  final margins = route.margins;
  return packStack(
    aspectRatios,
    width: (media.widthMm - margins.left - margins.right) * unit,
    height: (media.heightMm - margins.top - margins.bottom) * unit,
    lanes: stack.lanes,
    gap: stack.gap * unit,
    rows: stack.direction == StackDirection.rows,
  );
}

/// Packs items with the given [aspectRatios] (width / height) on sheets with an area of [width] by [height], and
/// returns the placements per sheet.
///
/// The area is divided into [lanes] columns of equal width, [gap] apart. Each item gets the width of a column, turned so it
/// uses the least height, and goes to the column that is filled least, below the items already there. So the sheet
/// fills from the top, and the rest of it stays in one piece. A sheet is full when the next item does not fit in any
/// column; that item starts the next sheet. An item that is higher than the area even when turned is scaled down to
/// fit, and centred in its column.
///
/// With [rows], the area is divided into [lanes] rows of equal height instead, which fill from the left, and each item is
/// turned to use the least width. That is the same packing with width and height swapped.
List<List<StackPlacement>> packStack(
  List<double> aspectRatios, {
  required double width,
  required double height,
  required int lanes,
  required double gap,
  bool rows = false,
}) {
  if (rows) {
    final transposed = _packColumns([for (final ratio in aspectRatios) 1 / ratio], width: height, height: width, columns: lanes, gap: gap);
    return [
      for (final sheet in transposed)
        [
          for (final placement in sheet)
            // Swapping both the box and the item keeps whether the item is turned.
            StackPlacement(
              item: placement.item,
              left: placement.top,
              top: placement.left,
              width: placement.height,
              height: placement.width,
              turned: placement.turned,
            ),
        ],
    ];
  }
  return _packColumns(aspectRatios, width: width, height: height, columns: lanes, gap: gap);
}

List<List<StackPlacement>> _packColumns(
  List<double> aspectRatios, {
  required double width,
  required double height,
  required int columns,
  required double gap,
}) {
  final columnWidth = (width - (columns - 1) * gap) / columns;
  if (columns < 1 || columnWidth <= 0 || height <= 0) {
    throw ArgumentError('No room for $columns columns $gap apart in an area of $width by $height');
  }
  // Leaves room for rounding errors in the sums of heights.
  const tolerance = 1e-6;

  final List<List<StackPlacement>> sheets = [];
  List<StackPlacement> sheet = [];
  // The bottom of the last item in each column, null for an empty column.
  List<double?> bottoms = List.filled(columns, null);

  for (final (index, aspectRatio) in aspectRatios.indexed) {
    final turned = aspectRatio < 1;
    final aspectOnSheet = turned ? 1 / aspectRatio : aspectRatio;
    double itemWidth = columnWidth, itemHeight = columnWidth / aspectOnSheet;
    if (itemHeight > height) {
      itemHeight = height;
      itemWidth = height * aspectOnSheet;
    }

    double topIn(int column) => switch (bottoms[column]) {
      final bottom? => bottom + gap,
      null => 0,
    };
    int column = 0;
    for (int candidate = 1; candidate < columns; candidate++) {
      if (topIn(candidate) < topIn(column)) column = candidate;
    }
    if (topIn(column) + itemHeight > height + tolerance) {
      sheets.add(sheet);
      sheet = [];
      bottoms = List.filled(columns, null);
      column = 0;
    }

    final top = topIn(column);
    sheet.add(StackPlacement(
      item: index,
      left: column * (columnWidth + gap) + (columnWidth - itemWidth) / 2,
      top: top,
      width: itemWidth,
      height: itemHeight,
      turned: turned,
    ));
    bottoms[column] = top + itemHeight;
  }

  if (sheet.isNotEmpty) sheets.add(sheet);
  return sheets;
}
