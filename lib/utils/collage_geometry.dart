/// Whether a collage of [photoCount] photos is laid out on its side, so it is turned a quarter when it is exported.
bool isCollageTurned(int photoCount) => const [0, 1, 4].contains(photoCount);

/// The collage padding of an exported collage on every side, as a fraction of the height of the exported image. This
/// is the bleed when printing it.
///
/// [padding] is in collage units, in which the collage without its padding is 1000 high (see the collage padding
/// setting). [aspectRatio] is the width of the exported image divided by its height. The padding is as wide on every
/// side, so for a turned collage, the side that was 1000 high is the width of the exported image.
double collageBleed({required double padding, required int photoCount, required double aspectRatio}) =>
    padding / (1000 + 2 * padding) * (isCollageTurned(photoCount) ? aspectRatio : 1);
