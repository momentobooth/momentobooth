import 'package:flutter_test/flutter_test.dart';
import 'package:momento_booth/hardware_control/printing/photo_placement.dart';
import 'package:momento_booth/hardware_control/printing/print_router.dart';
import 'package:momento_booth/hardware_control/printing/print_stack_packer.dart';
import 'package:momento_booth/models/print_routing_graph.dart';

/// A stack with a gap of 4 mm on media of 100 × 200 mm with margins of 10 mm, so a viewport of 80 × 180 mm.
PrintRoute _route({required bool borderless, StackDirection direction = StackDirection.columns}) => PrintRoute(
  printerNodeId: 'printer',
  printer: PrinterNodeData(queueId: 'printer', media: const PrintMedia(widthMm: 100, heightMm: 200), borderless: borderless),
  margins: const PrintMargins(top: 10, right: 10, bottom: 10, left: 10),
  stackNodeId: 'stack',
  stack: StackNodeData(gap: 4, direction: direction),
);

/// The items on each sheet, as (item, column left, top) per placement.
List<List<(int, double, double)>> _positions(List<List<StackPlacement>> sheets) => [
  for (final sheet in sheets) [for (final placement in sheet) (placement.item, placement.left, placement.top)],
];

void main() {
  group('packStack', () {
    test('stacks items in a single column with a gap, and starts a new sheet when the next does not fit', () {
      // 3:2 items in a column of 90 wide are 60 high: two fit in 125 with a gap of 5, three do not.
      final sheets = packStack([1.5, 1.5, 1.5], width: 90, height: 125, lanes: 1, gap: 5);

      expect(_positions(sheets), [
        [(0, 0.0, 0.0), (1, 0.0, 65.0)],
        [(2, 0.0, 0.0)],
      ]);
      expect(sheets.first.first, const StackPlacement(item: 0, left: 0, top: 0, width: 90, height: 60, turned: false));
    });

    test('turns portrait items to use the least height', () {
      final placement = packStack([0.5], width: 100, height: 200, lanes: 1, gap: 0).single.single;

      expect(placement, const StackPlacement(item: 0, left: 0, top: 0, width: 100, height: 50, turned: true));
    });

    test('divides the items over the columns so the highest column is as low as possible', () {
      // Columns of 50 wide: the square item is 50 high, the wide ones 25.
      final sheets = packStack([1, 2, 2, 2], width: 104, height: 200, lanes: 2, gap: 4);

      expect(_positions(sheets), [
        [(0, 0.0, 0.0), (1, 54.0, 0.0), (2, 54.0, 29.0), (3, 0.0, 54.0)],
      ]);
    });

    test('rearranges a sheet to make room for the next item', () {
      // Columns of 100 wide: square items are 100 high, the halves of a split print (2:1) 50. Each in the column
      // filled least, the halves would end up in different columns and leave no room for the last square item.
      final sheets = packStack([1, 1, 2, 2, 1], width: 200, height: 200, lanes: 2, gap: 0);

      expect(_positions(sheets), [
        [(0, 0.0, 0.0), (1, 100.0, 0.0), (2, 100.0, 100.0), (3, 100.0, 150.0), (4, 0.0, 100.0)],
      ]);
    });

    test('keeps the items in their order over the sheets', () {
      // Columns of 100 wide on an area of 150 high: the first two items take a column each, so the third starts a
      // new sheet, also though the small fourth one would still fit.
      final sheets = packStack([1, 1, 1, 4], width: 200, height: 150, lanes: 2, gap: 0);

      expect(_positions(sheets), [
        [(0, 0.0, 0.0), (1, 100.0, 0.0)],
        [(2, 0.0, 0.0), (3, 100.0, 0.0)],
      ]);
    });

    test('scales an item down that is higher than the sheet, and centres it in its column', () {
      final placement = packStack([1], width: 100, height: 50, lanes: 1, gap: 0).single.single;

      expect(placement, const StackPlacement(item: 0, left: 25, top: 0, width: 50, height: 50, turned: false));
    });

    test('fills rows from the left, turning items to use the least width', () {
      // Rows of 50 high: a portrait item (1:2) is 25 wide as it is, a landscape one (2:1) is 25 wide when turned.
      final sheets = packStack([0.5, 2, 0.5], width: 100, height: 103, lanes: 2, gap: 3, rows: true);

      expect(sheets, [
        [
          const StackPlacement(item: 0, left: 0, top: 0, width: 25, height: 50, turned: false),
          const StackPlacement(item: 1, left: 0, top: 53, width: 25, height: 50, turned: true),
          const StackPlacement(item: 2, left: 28, top: 0, width: 25, height: 50, turned: false),
        ],
      ]);
    });

    test('returns no sheets for no items', () {
      expect(packStack([], width: 100, height: 100, lanes: 1, gap: 0), isEmpty);
    });

    test('refuses columns that leave no room', () {
      expect(() => packStack([1], width: 10, height: 100, lanes: 2, gap: 10), throwsArgumentError);
      expect(() => packStack([1], width: 100, height: 100, lanes: 0, gap: 0), throwsArgumentError);
    });
  });

  test('stackItemsOf leaves out the bleed, which a half does not have where the halves meet', () {
    // A photo of 0.6 with a bleed of 0.1 of its height is 0.4 × 0.8 without its bleed.
    expect(stackItemsOf(0.6, split: false, bleed: 0.1).single, closeTo(0.5, 1e-9));
    expect(stackItemsOf(0.6, split: true, bleed: 0.1), [closeTo(0.25, 1e-9), closeTo(0.25, 1e-9)]);
  });

  group('packStackOn', () {
    test('keeps half the gap free within the viewport, for the bleed', () {
      final placement = packStackOn(_route(borderless: false), [1]).single.single;

      expect(placement, const StackPlacement(item: 0, left: 12, top: 12, width: 76, height: 76, turned: false));
    });

    test('lets items reach the edges of the viewport of borderless media, except at the far end of the lanes', () {
      final columns = packStackOn(_route(borderless: true), [1, 1, 1]);
      expect(columns.first.first, const StackPlacement(item: 0, left: 10, top: 10, width: 80, height: 80, turned: false));
      // Two fit in the 178 mm above the half gap at the bottom, with a gap between them; a third does not.
      expect(columns.first, hasLength(2));

      // For rows, the far end is at the right: the row is 180 high, and the room 78 wide. The item is centred in its
      // row.
      final rows = packStackOn(_route(borderless: true, direction: StackDirection.rows), [1]).single.single;
      expect(rows, const StackPlacement(item: 0, left: 10, top: 61, width: 78, height: 78, turned: false));
    });
  });

  group('stackItemVisibleRect', () {
    const placement = StackPlacement(item: 0, left: 10, top: 10, width: 80, height: 80, turned: false);
    const viewport = PageRect(10, 10, 80, 180);

    test('shows the bleed up to half the gap', () {
      expect(
        stackItemVisibleRect(placement, bleedSize: 3, gap: 4, viewport: viewport, borderless: false),
        const PageRect(8, 8, 84, 84),
      );
      expect(
        stackItemVisibleRect(placement, bleedSize: 1, gap: 4, viewport: viewport, borderless: false),
        const PageRect(9, 9, 82, 82),
      );
    });

    test('shows the whole bleed where the item reaches the edge of borderless media', () {
      expect(
        stackItemVisibleRect(placement, bleedSize: 3, gap: 4, viewport: viewport, borderless: true),
        const PageRect(7, 7, 86, 85),
      );
    });
  });
}
