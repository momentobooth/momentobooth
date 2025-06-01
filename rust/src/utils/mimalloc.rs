use core::alloc::{GlobalAlloc, Layout};
use std::ffi::c_void;

pub struct MiMalloc;

#[allow(clippy::inline_always)]
unsafe impl GlobalAlloc for MiMalloc {
    #[inline(always)]
    unsafe fn alloc(&self, layout: Layout) -> *mut u8 {
        unsafe { mi_malloc_aligned(layout.size(), layout.align()).cast() }
    }

    #[inline(always)]
    unsafe fn dealloc(&self, ptr: *mut u8, _layout: Layout) {
        unsafe { mi_free(ptr.cast()) };
    }

    #[inline(always)]
    unsafe fn alloc_zeroed(&self, layout: Layout) -> *mut u8 {
        unsafe { mi_zalloc_aligned(layout.size(), layout.align()).cast() }
    }

    #[inline(always)]
    unsafe fn realloc(&self, ptr: *mut u8, layout: Layout, new_size: usize) -> *mut u8 {
        unsafe { mi_realloc_aligned(ptr.cast(), new_size, layout.align()).cast() }
    }
}

unsafe extern "C" {
    unsafe fn mi_malloc_aligned(size: usize, alignment: usize) -> *mut c_void;
    unsafe fn mi_zalloc_aligned(size: usize, alignment: usize) -> *mut c_void;
    unsafe fn mi_realloc_aligned(p: *mut c_void, newsize: usize, alignment: usize) -> *mut c_void;
    unsafe fn mi_free(p: *mut c_void);
}
