use std::ffi::{c_int, c_void};

use dlopen::{symbor::{Library, Symbol}, Error as LibError};

use crate::dart_bridge::api::RawImage;

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
struct VideoRenderer {
    // TextureRgba pointer in flutter native.
    ptr: usize,
    width: usize,
    height: usize,
    on_rgba_func: Option<Symbol<'static, FlutterRgbaRendererPluginOnRgba>>,
}

impl Default for VideoRenderer {
    fn default() -> Self {
        let on_rgba_func = match &*TEXTURE_RGBA_RENDERER_PLUGIN {
            Ok(lib) => {
                let find_sym_res = unsafe {
                    lib.symbol::<FlutterRgbaRendererPluginOnRgba>("FlutterRgbaRendererPluginOnRgba")
                };
                match find_sym_res {
                    Ok(sym) => Some(sym),
                    Err(e) => {
                        //log::error!("Failed to find symbol FlutterRgbaRendererPluginOnRgba, {e}");
                        None
                    }
                }
            }
            Err(e) => {
                //log::error!("Failed to load texture rgba renderer plugin, {e}");
                None
            }
        };
        Self {
            ptr: 0,
            width: 0,
            height: 0,
            on_rgba_func,
        }
    }
}

impl VideoRenderer {
    #[inline]
    pub fn set_size(&mut self, width: usize, height: usize) {
        self.width = width;
        self.height = height;
    }

    pub fn on_rgba(&self, rgba: RawImage) {
        if self.ptr == usize::default() {
            return;
        }

        // It is also Ok to skip this check.
        if self.width != rgba.width || self.height != rgba.height {
            return;
        }

        if let Some(func) = &self.on_rgba_func {
            unsafe {
                func(
                    self.ptr as _,
                    rgba.data.as_ptr() as _,
                    rgba.data.len() as _,
                    rgba.width as _,
                    rgba.height as _,
                    0,
                )
            };
        }
    }
}
