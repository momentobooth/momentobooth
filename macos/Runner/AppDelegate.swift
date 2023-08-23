import Cocoa
import FlutterMacOS

@NSApplicationMain
class AppDelegate: FlutterAppDelegate {
  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    // See: https://cjycode.com/flutter_rust_bridge/integrate/ios_headers.html
    let dummyReturnValue = dummy_method_to_enforce_bundling()
    doNothing(with: dummyReturnValue)
    return true
  }

  @inline(never)
  func doNothing(with object: Any) {
    // This method does nothing with the object parameter
  }
}
