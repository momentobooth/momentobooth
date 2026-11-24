import 'dart:math' as math;

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
/// uses the least height. The items go on the sheets in their order: a sheet takes items until the next one does not
/// fit, and that item starts the next sheet. Within a sheet, the items are divided over the columns so the longest
/// column is as short as possible, and each column fills from the top in the order of the items. So the rest of the
/// sheet stays in one piece and is as large as possible. An item that is higher than the area even when turned is
/// scaled down to fit, and centred in its column.
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

  final items = [
    for (final aspectRatio in aspectRatios)
      () {
        final turned = aspectRatio < 1;
        final aspectOnSheet = turned ? 1 / aspectRatio : aspectRatio;
        double itemWidth = columnWidth, itemHeight = columnWidth / aspectOnSheet;
        if (itemHeight > height) {
          itemHeight = height;
          itemWidth = height * aspectOnSheet;
        }
        return (width: itemWidth, height: itemHeight, turned: turned);
      }(),
  ];

  List<StackPlacement> place(int first, List<int> columnOf) {
    final List<double> tops = List.filled(columns, 0);
    return [
      for (final (offset, column) in columnOf.indexed)
        () {
          final item = items[first + offset];
          final top = tops[column];
          tops[column] = top + item.height + gap;
          return StackPlacement(
            item: first + offset,
            left: column * (columnWidth + gap) + (columnWidth - item.width) / 2,
            top: top,
            width: item.width,
            height: item.height,
            turned: item.turned,
          );
        }(),
    ];
  }

  final List<List<StackPlacement>> sheets = [];
  // The first item of the open sheet, and the column of each item on it.
  int first = 0;
  List<int> columnOf = const [];
  for (int next = 0; next < items.length; next++) {
    final arranged = _arrangeInColumns([for (int i = first; i <= next; i++) items[i].height], columns: columns, height: height, gap: gap);
    if (arranged != null) {
      columnOf = arranged;
    } else {
      sheets.add(place(first, columnOf));
      first = next;
      // A single item always fits, as it is scaled down to the height of the area.
      columnOf = const [0];
    }
  }
  if (items.isNotEmpty) sheets.add(place(first, columnOf));
  return sheets;
}

/// Divides items with the given [heights] over [columns], so the highest column is as low as possible. Returns the column
/// of each item, or null when they do not fit within [height]. The columns are numbered in the order of their first
/// item.
///
/// Starts with the highest item first, each in the column that is filled least, which is usually best already. When
/// that leaves room for doing better, it searches the other divisions, with a limit on the steps so it never takes long.
List<int>? _arrangeInColumns(List<double> heights, {required int columns, required double height, required double gap}) {
  // Leaves room for rounding errors in the sums of heights.
  const tolerance = 1e-6;
  const maxSteps = 10000;

  // With a gap below every item, a column of items fits when it is no higher than the area plus one gap.
  final sizes = [for (final itemHeight in heights) itemHeight + gap];
  final order = [for (int i = 0; i < sizes.length; i++) i]
    ..sort((a, b) => sizes[b] != sizes[a] ? sizes[b].compareTo(sizes[a]) : a.compareTo(b));

  final List<double> loads = List.filled(columns, 0);
  List<int> best = List.filled(sizes.length, 0);
  for (final i in order) {
    int column = 0;
    for (int candidate = 1; candidate < columns; candidate++) {
      if (loads[candidate] < loads[column]) column = candidate;
    }
    best[i] = column;
    loads[column] += sizes[i];
  }
  double bestHighest = loads.reduce(math.max);

  // No division does better than the highest item, or than all items spread evenly.
  final total = sizes.fold(0.0, (sum, size) => sum + size);
  final lowest = math.max(sizes[order.first], total / columns);
  if (bestHighest > lowest + tolerance) {
    final current = List<int>.filled(sizes.length, 0);
    loads.fillRange(0, columns, 0);
    int steps = 0;
    void search(int placed) {
      if (++steps > maxSteps || bestHighest <= lowest + tolerance) return;
      if (placed == sizes.length) {
        bestHighest = loads.reduce(math.max);
        best = [...current];
        return;
      }
      final i = order[placed];
      // Columns that are filled equally lead to the same divisions, so only the first of them is tried.
      final tried = <double>{};
      for (int column = 0; column < columns; column++) {
        if (!tried.add(loads[column]) || loads[column] + sizes[i] >= bestHighest - tolerance) continue;
        loads[column] += sizes[i];
        current[i] = column;
        search(placed + 1);
        loads[column] -= sizes[i];
      }
    }
    search(0);
  }
  if (bestHighest > height + gap + tolerance) return null;

  // Number the columns in the order of their first item, so the first item is at the left.
  final Map<int, int> renumbered = {};
  return [for (final column in best) renumbered.putIfAbsent(column, () => renumbered.length)];
}
