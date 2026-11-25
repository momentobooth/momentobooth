/// A rectangle on a page, in any unit.
class PageRect {

  final double left;
  final double top;
  final double width;
  final double height;

  const PageRect(this.left, this.top, this.width, this.height);

  double get right => left + width;
  double get bottom => top + height;

  @override
  bool operator ==(Object other) =>
      other is PageRect && other.left == left && other.top == top && other.width == width && other.height == height;

  @override
  int get hashCode => Object.hash(left, top, width, height);

  @override
  String toString() => 'PageRect($left, $top, $width × $height)';

}

/// The sides of an area where the printer cuts the paper: sides that lie on the edge of the viewport of borderless
/// media. A photo that reaches such a side puts its bleed beyond it, so the bleed is cut off. On every other side, the
/// bleed stays inside the area, to be cut off by hand.
class CutSides {

  final bool left;
  final bool top;
  final bool right;
  final bool bottom;

  const CutSides({this.left = false, this.top = false, this.right = false, this.bottom = false});

  static const CutSides none = CutSides();
  static const CutSides all = CutSides(left: true, top: true, right: true, bottom: true);

  /// The sides of the cell at [row] and [column] of a grid that fills the viewport of borderless media.
  factory CutSides.ofCell({required int row, required int column, required int rows, required int columns}) => CutSides(
    left: column == 0,
    top: row == 0,
    right: column == columns - 1,
    bottom: row == rows - 1,
  );

  @override
  bool operator ==(Object other) =>
      other is CutSides && other.left == left && other.top == top && other.right == right && other.bottom == bottom;

  @override
  int get hashCode => Object.hash(left, top, right, bottom);

}

/// Where a photo goes on the page.
class PhotoPlacement {

  /// The whole photo, its bleed included, as it lies on the page (so after turning). It may reach beyond the area the
  /// photo was placed in, on the sides where the printer cuts.
  final PageRect rect;

  /// Whether the photo is turned a quarter, to match the orientation of its area.
  final bool turned;

  const PhotoPlacement(this.rect, {required this.turned});

  @override
  String toString() => 'PhotoPlacement($rect${turned ? ', turned' : ''})';

}

/// Fits a photo in [area], turned a quarter when that matches the orientation of the area better.
///
/// The photo is [aspectRatio] (width divided by height) and has a bleed of [bleed] on every side, as a fraction of its
/// height: the collage padding. The photo is as large as possible, such that it fits the area except for its bleed on
/// the [cut] sides it reaches. There, the bleed lies beyond the area, so the visible part of the photo ends exactly
/// where the printer cuts. Without cut sides, the whole photo fits the area.
///
/// In a direction where only one side is cut, the photo lies against that side, with its bleed beyond it, so the space
/// it leaves is all on the other side. In a grid, the photos then lie against the edges of the viewport and the space
/// between them is in one strip, which saves cuts. In other directions, the photo is centred.
PhotoPlacement placePhoto(PageRect area, {required double aspectRatio, double bleed = 0, CutSides cut = CutSides.none}) {
  final turned = (aspectRatio > 1) != (area.width > area.height);
  // The size of the photo and its bleed, relative to its height and in the orientation of the page.
  final width = turned ? 1.0 : aspectRatio;
  final height = turned ? aspectRatio : 1.0;

  int count(bool a, bool b) => (a ? 1 : 0) + (b ? 1 : 0);
  final scale = [
    area.width / (width - bleed * count(cut.left, cut.right)),
    area.height / (height - bleed * count(cut.top, cut.bottom)),
  ].reduce((a, b) => a < b ? a : b);

  final w = width * scale, h = height * scale, bleedSize = bleed * scale;

  // Where the photo starts in one direction: against the cut side with its bleed beyond it when only one side is cut,
  // and otherwise centred. The scale makes sure the photo without its bleed on the cut side fits the area.
  double start(double areaStart, double areaSize, double size, bool cutStart, bool cutEnd) {
    if (cutStart && !cutEnd) return areaStart - bleedSize;
    if (cutEnd && !cutStart) return areaStart + areaSize + bleedSize - size;
    return areaStart - (size - areaSize) / 2;
  }

  return PhotoPlacement(
    PageRect(
      start(area.left, area.width, w, cut.left, cut.right),
      start(area.top, area.height, h, cut.top, cut.bottom),
      w,
      h,
    ),
    turned: turned,
  );
}
