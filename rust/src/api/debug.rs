use core::panic;
use std::fs;
use anyhow::{bail, Result};

pub fn panic() {
    panic!("This is a test panic for debug purposes")
}

pub fn fail() -> Result<()> {
    bail!("This is a test error for debug purposes")
}

pub fn file_read_fail() -> Result<()> {
    fs::read("C:\\This\\Probably\\Does\\Not\\Exist.txt")?;
    Ok(())
}
