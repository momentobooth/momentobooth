import 'package:fluent_ui/fluent_ui.dart' show ComboBoxItem, Text;
import 'package:momento_booth/hardware_control/live_view_streaming/live_view_source.dart';
import 'package:momento_booth/src/rust/api/nokhwa.dart';
import 'package:momento_booth/src/rust/hardware_control/live_view/nokhwa.dart';
import 'package:momento_booth/src/rust/models/images.dart';
import 'package:momento_booth/src/rust/models/live_view.dart';
import 'package:momento_booth/src/rust/utils/image_processing.dart';

class NokhwaCamera extends LiveViewSource {

  @override
  final String id;

  @override
  final String friendlyName;

  late int handleId;

  static Future<void>? _initFuture;

  NokhwaCamera({required this.id, required this.friendlyName});

  // //////////// //
  // List cameras //
  // //////////// //

  static Future<List<NokhwaCamera>> getAllCameras() async {
    return []; // Temp fix for crash
    // await _ensureLibraryInitialized();
    // List<NokhwaCameraInfo> cameras = await nokhwaGetCameras();
    // return cameras.map((camera) => NokhwaCamera(
    //   id: camera.friendlyName,
    //   friendlyName: camera.friendlyName,
    // )).toList();
  }

  static Future<List<ComboBoxItem<String>>> getCamerasAsComboBoxItems() async =>
      (await getAllCameras()).map((value) => value.toComboBoxItem()).toList();

  ComboBoxItem<String> toComboBoxItem() => ComboBoxItem(value: id, child: Text(friendlyName));

  // ////////////// //
  // Control camera //
  // ////////////// //

  @override
  Future<void> openStream({
    required BigInt texturePtr,
    List<ImageOperation> operations = const [],
  }) async {
    await _ensureLibraryInitialized();
    handleId = await nokhwaOpenCamera(
      friendlyName: friendlyName,
      operations: operations,
      texturePtr: texturePtr,
    );
  }

  @override
  Future<void> setOperations(List<ImageOperation> operations) {
    return nokhwaSetOperations(handleId: handleId, operations: operations);
  }

  @override
  Future<RawImage?> getLastFrame() => nokhwaGetLastFrame(handleId: handleId);

  @override
  Future<CameraState> getCameraState() => nokhwaGetCameraStatus(handleId: handleId);

  @override
  Future<void> dispose() => nokhwaCloseCamera(handleId: handleId);

  static Future<void> _ensureLibraryInitialized() async {
    _initFuture ??= nokhwaInitialize();
    await _initFuture;
  }

}
