
import 'package:fluent_ui/fluent_ui.dart' show ComboBoxItem, Text;
import 'package:momento_booth/hardware_control/live_view_streaming/live_view_source.dart';
import 'package:momento_booth/rust_bridge/library_api.generated.dart';
import 'package:momento_booth/rust_bridge/library_bridge.dart';

class Gphoto2Camera extends LiveViewSource {

  late int handleId;

  Gphoto2Camera({required super.id, required super.friendlyName});

  // //////////// //
  // List cameras //
  // //////////// //

  static Future<List<Gphoto2Camera>> getAllCameras() async {
    List<Gphoto2CameraInfo> cameras = await rustLibraryApi.gphoto2GetCameras();
    return cameras.map((camera) => Gphoto2Camera(
      id: "${camera.port}/${camera.model}",
      friendlyName: "${camera.model} (at ${camera.port})",
    )).toList();
  }

  static Future<List<ComboBoxItem<String>>> getCamerasAsComboBoxItems() async =>
      (await getAllCameras()).map((value) => value.toComboBoxItem()).toList();

  ComboBoxItem<String> toComboBoxItem() => ComboBoxItem(value: id, child: Text(friendlyName));

  // ////////////// //
  // Control camera //
  // ////////////// //

  @override
  Future<void> openStream({required int texturePtr}) async {
    var split = id.split("/");
    await rustLibraryApi.gphoto2OpenCamera(model: split[1], port: split[0], operations: [
      const ImageOperation.cropToAspectRatio(3 / 2),
    ], texturePtr: texturePtr);
  }

  @override
  Future<RawImage?> getLastFrame() => rustLibraryApi.nokhwaGetLastFrame(handleId: handleId);

  @override
  Future<CameraState> getCameraState() => Future.value(const CameraState(isStreaming: true, validFrameCount: 0, errorFrameCount: 0, lastFrameWasValid: true));

  @override
  Future<void> dispose() => rustLibraryApi.nokhwaCloseCamera(handleId: handleId);

}
