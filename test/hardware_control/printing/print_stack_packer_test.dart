import 'package:flutter_test/flutter_test.dart';
import 'package:momento_booth/hardware_control/printing/print_stack_packer.dart';

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
}
