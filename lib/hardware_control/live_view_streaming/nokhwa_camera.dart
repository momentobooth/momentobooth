import 'package:fluent_ui/fluent_ui.dart' show ComboBoxItem, Text;
import 'package:momento_booth/hardware_control/live_view_streaming/live_view_source.dart';
import 'package:momento_booth/rust_bridge/library_api.generated.dart';
import 'package:momento_booth/rust_bridge/library_bridge.dart';

class NokhwaCamera extends LiveViewSource {

  late int handleId;

  NokhwaCamera({required super.id, required super.friendlyName});

  // //////////// //
  // List cameras //
  // //////////// //

  static Future<List<NokhwaCamera>> getAllCameras() async {
    List<NokhwaCameraInfo> cameras = await rustLibraryApi.nokhwaGetCameras();
    return cameras.map((camera) => NokhwaCamera(
      id: camera.friendlyName,
      friendlyName: camera.friendlyName,
    )).toList();
  }

  static Future<List<ComboBoxItem<String>>> getCamerasAsComboBoxItems() async =>
      (await getAllCameras()).map((value) => value.toComboBoxItem()).toList();

  ComboBoxItem<String> toComboBoxItem() => ComboBoxItem(value: friendlyName, child: Text(friendlyName));

  // ////////////// //
  // Control camera //
  // ////////////// //

  @override
  Future<void> openStream({required int texturePtr}) async {
    handleId = await rustLibraryApi.nokhwaOpenCamera(friendlyName: friendlyName, operations: [
      ImageOperation.cropToAspectRatio(3 / 2),
    ], texturePtr: texturePtr);
  }

  @override
  Future<RawImage?> getLastFrame() => rustLibraryApi.nokhwaGetLastFrame(handleId: handleId);

  @override
  Future<CameraState> getCameraState() => rustLibraryApi.nokhwaGetCameraStatus(handleId: handleId);

  @override
  Future<void> dispose() => rustLibraryApi.nokhwaCloseCamera(handleId: handleId);

}
