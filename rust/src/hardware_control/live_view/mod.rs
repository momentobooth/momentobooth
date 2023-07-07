pub(crate) mod nokhwa;
pub(crate) mod white_noise;

#[cfg(not(target_os = "macos"))]
pub(crate) mod gphoto2;
