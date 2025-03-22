#[derive(Clone)]
pub struct VersionInfo {
    pub rust_version: String,
    pub rust_target: String,
    pub library_version: String,
    pub libgphoto2_version: String,
    pub libusb_version: String,
    pub libgexiv2_version: String,
    pub libexiv2_version: String,
}
