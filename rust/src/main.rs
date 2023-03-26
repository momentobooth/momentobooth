mod hardware_control;

fn main() {
    let x = hardware_control::live_view::nokhwa_capture_device::get_webcams();
    let y: Vec<String> = x.iter().map(|f| f.friendly_name.to_string()).collect();
    println!(
        "Cameras: {}", y.len()
    );
    println!(
        "Camera names: {:?}", y
    );
}
