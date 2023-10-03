
import 'dart:typed_data';

import 'package:fluent_ui/fluent_ui.dart' show ComboBoxItem, Text;
import 'package:momento_booth/exceptions/gphoto2_exception.dart';
import 'package:momento_booth/hardware_control/live_view_streaming/live_view_source.dart';
import 'package:momento_booth/hardware_control/photo_capturing/photo_capture_method.dart';
import 'package:momento_booth/managers/helper_library_initialization_manager.dart';
import 'package:momento_booth/managers/settings_manager.dart';
import 'package:momento_booth/rust_bridge/library_api.generated.dart';
import 'package:momento_booth/rust_bridge/library_bridge.dart';

class GPhoto2Camera extends PhotoCaptureMethod implements LiveViewSource {

  @override
  final String id;

  @override
  final String friendlyName;

  late int handleId;
  bool isOpened = false;

  GPhoto2Camera({required this.id, required this.friendlyName});

  // //////////// //
  // List cameras //
  // //////////// //

  static Future<List<GPhoto2Camera>> getAllCameras() async {
    await _ensureLibraryInitialized();
    List<GPhoto2CameraInfo> cameras = await rustLibraryApi.gphoto2GetCameras();
    return cameras.map((camera) => GPhoto2Camera(
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
    await _ensureLibraryInitialized();
    var split = id.split("/");
    handleId = await rustLibraryApi.gphoto2OpenCamera(model: split[1], port: split[0], specialHandling: SettingsManager.instance.settings.hardware.gPhoto2SpecialHandling.toHelperLibraryEnumValue());
    isOpened = true;
    await rustLibraryApi.gphoto2StartLiveview(handleId: handleId, operations: [
      const ImageOperation.cropToAspectRatio(3 / 2),
    ], texturePtr: texturePtr);

    rustLibraryApi.gphoto2SetExtraFileCallback(handleId: handleId).listen((element) {
      storePhotoSafe(element.filename, element.data);
    });
  }

  @override
  Future<RawImage?> getLastFrame() => rustLibraryApi.gphoto2GetLastFrame(handleId: handleId);

  @override
  Future<CameraState> getCameraState() => rustLibraryApi.gphoto2GetCameraStatus(handleId: handleId);

  @override
  Future<void> dispose() async {
    if (isOpened) await rustLibraryApi.gphoto2CloseCamera(handleId: handleId);
    isOpened = false;
  }

  @override
  Future<Uint8List> captureAndGetPhoto() async {
    await _ensureLibraryInitialized();
    String captureTarget = SettingsManager.instance.settings.hardware.gPhoto2CaptureTarget;
    var capture = await rustLibraryApi.gphoto2CapturePhoto(handleId: handleId, captureTargetValue: captureTarget);
    await storePhotoSafe(capture.filename, capture.data);

    return capture.data;
  }

  @override
  Duration get captureDelay => Duration(milliseconds: SettingsManager.instance.settings.hardware.captureDelayGPhoto2);

  Future<void> autoFocus() async {
    await _ensureLibraryInitialized();
    await rustLibraryApi.gphoto2AutoFocus(handleId: handleId);
  }

  @override
  Future<void> clearPreviousEvents() async {
    await _ensureLibraryInitialized();
    await rustLibraryApi.gphoto2ClearEvents(handleId: handleId);
  }

  static Future<void> _ensureLibraryInitialized() async {
    if (!await HelperLibraryInitializationManager.instance.gphoto2InitializationResult) {
      throw GPhoto2Exception('gPhoto2 implementation cannot be used due to initialization failure.');
    }
  }

}
