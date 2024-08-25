use std::env;
use std::fs::File;
use std::io::Write;
use std::path::PathBuf;

fn main() {
    insert_target_name();
    generate_exiv2_bindings();
}

fn insert_target_name() {
    // Find target folder
    let out_dir = env::var("OUT_DIR").unwrap();

    // Open file "target_name.txt"
    let target_file_path = format!("{}/target_name.txt", out_dir);
    let mut file = File::create(target_file_path).unwrap();

    // Write target name to file
    let target = env::var("TARGET").unwrap();
    file.write_all(target.as_bytes()).unwrap();
}

fn generate_exiv2_bindings() {
    let pkg_config_result = pkg_config::Config::new().probe("exiv2").unwrap();

    let mut builder = bindgen::Builder::default();
    for path in pkg_config_result.include_paths {
        let header_path = path.join("exiv2").join("exiv2.hpp");
        if header_path.exists() {
            builder = builder.header(header_path.to_str().unwrap())
        }
    }
    let bindings = builder.parse_callbacks(Box::new(bindgen::CargoCallbacks::new())).allowlist_function("Exiv2::version").generate().expect("Unable to generate bindings");

    let out_path = PathBuf::from(env::var("OUT_DIR").unwrap());
    bindings
        .write_to_file(out_path.join("exiv2_bindings.rs"))
        .expect("Couldn't write bindings!");
}
