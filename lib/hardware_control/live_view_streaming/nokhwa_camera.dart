import 'package:fluent_ui/fluent_ui.dart' show ComboBoxItem, Text;
import 'package:momento_booth/exceptions/nokhwa_exception.dart';
import 'package:momento_booth/hardware_control/live_view_streaming/live_view_source.dart';
import 'package:momento_booth/managers/_all.dart';
import 'package:momento_booth/rust_bridge/library_api.generated.dart';
import 'package:momento_booth/rust_bridge/library_bridge.dart';

class NokhwaCamera extends LiveViewSource {

  @override
  final String id;

  @override
  final String friendlyName;

  late int handleId;

  NokhwaCamera({required this.id, required this.friendlyName});

  // //////////// //
  // List cameras //
  // //////////// //

  static Future<List<NokhwaCamera>> getAllCameras() async {
    await _ensureLibraryInitialized();
    List<NokhwaCameraInfo> cameras = await rustLibraryApi.nokhwaGetCameras();
    return cameras.map((camera) => NokhwaCamera(
      id: camera.friendlyName,
      friendlyName: camera.friendlyName,
    )).toList();
  }

  static Future<List<ComboBoxItem<String>>> getCamerasAsComboBoxItems() async =>
      (await getAllCameras()).map((value) => value.toComboBoxItem()).toList();

  ComboBoxItem<String> toComboBoxItem() => ComboBoxItem(value: id, child: Text(friendlyName));

  // ////////////// //
  // Control camera //
  // ////////////// //

  @override
  Future<void> openStream({
    required int texturePtr,
    List<ImageOperation> operations = const [],
  }) async {
    await _ensureLibraryInitialized();
    handleId = await rustLibraryApi.nokhwaOpenCamera(
      friendlyName: friendlyName,
      operations: operations,
      texturePtr: texturePtr,
    );
  }

  @override
  Future<void> setOperations(List<ImageOperation> operations) {
    return rustLibraryApi.nokhwaSetOperations(handleId: handleId, operations: operations);
  }

  @override
  Future<RawImage?> getLastFrame() => rustLibraryApi.nokhwaGetLastFrame(handleId: handleId);

  @override
  Future<CameraState> getCameraState() => rustLibraryApi.nokhwaGetCameraStatus(handleId: handleId);

  @override
  Future<void> dispose() => rustLibraryApi.nokhwaCloseCamera(handleId: handleId);

  static Future<void> _ensureLibraryInitialized() async {
    if (!await HelperLibraryInitializationManager.instance.nokhwaInitializationResult) {
      throw NokhwaException('Nokhwa implementation cannot be used due to initialization failure.');
    }
  }

}
