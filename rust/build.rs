use std::env;
use std::fs::File;
use std::io::Write;
use std::path::PathBuf;

fn main() {
    insert_target_name();
    generate_exiv2_bindings();
    if cfg!(target_os = "windows") {
        link_mimalloc();
    }
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

    let mut builder = bindgen::Builder::default().clang_arg("-xc++").clang_arg("-std=c++11");
    for path in pkg_config_result.include_paths {
        builder = builder.clang_arg(format!("-I{}", path.to_str().unwrap()));

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

fn link_mimalloc() {
    // Determine if we are Debug or Release.
    let profile = env::var("PROFILE").unwrap();
    let config_dir = match profile.as_str() {
        "debug" => "Debug",
        "release" => "Release",
        other => {
            panic!("Unknown PROFILE: {}", other);
        }
    };

    // Relative path to already built mimalloc.
    let mimalloc_lib_dir = PathBuf::from(env::var("CARGO_MANIFEST_DIR").unwrap())
        .join("..") // van rust_lib_momento_booth
        .join("build")
        .join("windows")
        .join("x64")
        .join("mimalloc")
        .join(config_dir);

    println!("cargo:rustc-link-search=native={}", mimalloc_lib_dir.display());
    println!("cargo:rustc-link-lib=dylib=mimalloc.dll");
    println!("cargo:rerun-if-changed={}", mimalloc_lib_dir.display());
}
