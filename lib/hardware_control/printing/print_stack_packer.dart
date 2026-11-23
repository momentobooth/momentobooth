import 'package:flutter/foundation.dart';

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

/// Packs items with the given [aspectRatios] (width / height) on sheets with an area of [width] by [height], and
/// returns the placements per sheet.
///
/// The area is divided into [columns] of equal width, [gap] apart. Each item gets the width of a column, turned so it
/// uses the least height, and goes to the column that is filled least, below the items already there. So the sheet
/// fills from the top, and the rest of it stays in one piece. A sheet is full when the next item does not fit in any
/// column; that item starts the next sheet. An item that is higher than the area even when turned is scaled down to
/// fit, and centred in its column.
///
/// Packing in rows instead, filling the sheet from the left, is the same with width and height swapped.
List<List<StackPlacement>> packStack(
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
