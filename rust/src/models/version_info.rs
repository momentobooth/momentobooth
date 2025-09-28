#[derive(Clone)]
pub struct VersionInfo {
    pub rust_version: String,
    pub rust_target: String,
    pub library_version: String,
    pub libgphoto2_version: String,
    pub libusb_version: String,
}
