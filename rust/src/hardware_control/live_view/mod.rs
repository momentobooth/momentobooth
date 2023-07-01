pub(crate) mod nokhwa;
pub(crate) mod white_noise;

#[cfg(any(not(target_os = "macos"), debug_assertions))]
pub(crate) mod gphoto2;
