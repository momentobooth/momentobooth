import 'package:flutter_test/flutter_test.dart';
import 'package:momento_booth/hardware_control/printing/photo_placement.dart';

const _area = PageRect(0, 0, 100, 200);

void _expectRect(PhotoPlacement placement, PageRect expected, {bool turned = false}) {
  final rect = placement.rect;
  expect([rect.left, rect.top, rect.width, rect.height], [
    closeTo(expected.left, 1e-9),
    closeTo(expected.top, 1e-9),
    closeTo(expected.width, 1e-9),
    closeTo(expected.height, 1e-9),
  ]);
  expect(placement.turned, turned);
}

void main() {
  group('placePhoto', () {
    test('fits the photo in the area and centres it', () {
      _expectRect(placePhoto(_area, aspectRatio: 0.5), const PageRect(0, 0, 100, 200));
      _expectRect(placePhoto(_area, aspectRatio: 1), const PageRect(0, 50, 100, 100));
    });

    test('turns a photo to the orientation of the area', () {
      _expectRect(placePhoto(_area, aspectRatio: 2), const PageRect(0, 0, 100, 200), turned: true);
    });

    test('keeps the bleed inside the area when no side is cut', () {
      _expectRect(placePhoto(_area, aspectRatio: 0.6, bleed: 0.1), const PageRect(0, (200 - 100 / 0.6) / 2, 100, 100 / 0.6));
    });

    // A photo of 0.6 with a bleed of 0.1 of its height is 0.4 × 0.8 without its bleed: the shape of the area.
    test('puts the bleed beyond the cut sides, so the photo without its bleed fills the area', () {
      _expectRect(placePhoto(_area, aspectRatio: 0.6, bleed: 0.1, cut: CutSides.all), const PageRect(-25, -25, 150, 250));
    });

    test('keeps the bleed inside on the sides that are not cut, and on cut sides the photo does not reach', () {
      // The left cell of two side by side: the right side is cut by hand. The photo fills the width, and does not
      // reach the top and bottom.
      const cut = CutSides(left: true, top: true, bottom: true);
      _expectRect(placePhoto(_area, aspectRatio: 0.6, bleed: 0.1, cut: cut), const PageRect(-20, 0, 120, 200));
    });

    // A square photo with a bleed of 0.1 fills the width of the area without its bleed (125 with it), and leaves
    // space in the height.
    test('puts a photo that does not fill the area against the only cut side of that direction', () {
      // The top and bottom cells of a grid of two rows: their photos lie against the edges of the viewport, so the
      // space between them is in one strip.
      _expectRect(
        placePhoto(_area, aspectRatio: 1, bleed: 0.1, cut: const CutSides(left: true, top: true, right: true)),
        const PageRect(-12.5, -12.5, 125, 125),
      );
      _expectRect(
        placePhoto(_area, aspectRatio: 1, bleed: 0.1, cut: const CutSides(left: true, right: true, bottom: true)),
        const PageRect(-12.5, 87.5, 125, 125),
      );
    });
  });

  test('CutSides.ofCell cuts the sides of a cell on the edge of the grid', () {
    expect(CutSides.ofCell(row: 0, column: 0, rows: 2, columns: 2), const CutSides(left: true, top: true));
    expect(CutSides.ofCell(row: 1, column: 1, rows: 2, columns: 2), const CutSides(right: true, bottom: true));
    expect(CutSides.ofCell(row: 0, column: 0, rows: 1, columns: 1), CutSides.all);
  });
}
