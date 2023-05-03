use std::ffi::{c_int, c_void};

use dlopen::{symbor::{Library, Symbol}, Error as LibError};

use crate::{dart_bridge::api::RawImage, log_error};

#[cfg(all(target_os = "windows"))]
lazy_static::lazy_static! {
    pub static ref TEXTURE_RGBA_RENDERER_PLUGIN: Result<Library, LibError> = Library::open("texture_rgba_renderer_plugin.dll");
}

#[cfg(all(target_os = "linux"))]
lazy_static::lazy_static! {
    pub static ref TEXTURE_RGBA_RENDERER_PLUGIN: Result<Library, LibError> = Library::open("libtexture_rgba_renderer_plugin.so");
}

#[cfg(all(target_os = "macos"))]
lazy_static::lazy_static! {
    pub static ref TEXTURE_RGBA_RENDERER_PLUGIN: Result<Library, LibError> = Library::open_self();
}

pub type FlutterRgbaRendererPluginOnRgba = unsafe extern "C" fn(
    texture_rgba: *mut c_void,
    buffer: *const u8,
    len: c_int,
    width: c_int,
    height: c_int,
    dst_rgba_stride: c_int,
);

#[derive(Clone)]
pub struct FlutterTexture {
    ptr: usize, // TextureRgba pointer in flutter native.
    width: usize,
    height: usize,
    on_rgba_func: Option<Symbol<'static, FlutterRgbaRendererPluginOnRgba>>,
}

impl FlutterTexture {
    pub fn new(ptr: usize, width: usize, height: usize) -> Self {
        let on_rgba_func = match &*TEXTURE_RGBA_RENDERER_PLUGIN {
            Ok(lib) => {
                let find_sym_res = unsafe {
                    lib.symbol::<FlutterRgbaRendererPluginOnRgba>("FlutterRgbaRendererPluginOnRgba")
                };
                match find_sym_res {
                    Ok(sym) => Some(sym),
                    Err(error) => {
                        log_error("Failed to find symbol FlutterRgbaRendererPluginOnRgba: ".to_string() + &error.to_string());
                        None
                    }
                }
            }
            Err(error) => {
                log_error("Failed to load texture rgba renderer plugin: ".to_string() + &error.to_string());
                None
            }
        };
        Self {
            ptr,
            width,
            height,
            on_rgba_func,
        }
    }
}

impl FlutterTexture {
    pub fn set_size(&mut self, width: usize, height: usize) {
        self.width = width;
        self.height = height;
    }

    pub fn on_rgba(&self, raw_image: RawImage) {
        if self.ptr == usize::default() {
            return;
        }

        if self.width != raw_image.width || self.height != raw_image.height {
            return;
        }

        if let Some(func) = &self.on_rgba_func {
            unsafe {
                func(
                    self.ptr as _,
                    raw_image.data.as_ptr() as _,
                    raw_image.data.len() as _,
                    raw_image.width as _,
                    raw_image.height as _,
                    0,
                )
            };
        }
    }
}
