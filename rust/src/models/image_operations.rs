#[derive(Clone, Copy)]
pub enum ImageOperation {
    CropContentRegion,
    CropToAspectRatio(f64),
    Rotate(Rotation),
    Flip(FlipAxis),
    Resize(u32, u32),
}

#[derive(Clone, Copy)]
pub enum Rotation {
    Rotate90,
    Rotate180,
    Rotate270,
}

#[derive(Clone, Copy)]
pub enum FlipAxis {
    Horizontally,
    Vertically,
}
