use std::env;
use std::fs::File;
use std::io::Write;

fn main() {
    // Find target folder
    let out_dir = env::var("OUT_DIR").unwrap();

    // Open file "target_name.txt"
    let target_file_path = format!("{}/target_name.txt", out_dir);
    let mut file = File::create(target_file_path).unwrap();

    // Write target name to file
    let target = env::var("TARGET").unwrap();
    file.write_all(target.as_bytes()).unwrap();
}
