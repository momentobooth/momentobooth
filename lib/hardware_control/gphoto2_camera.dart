
import 'dart:async';

import 'package:fluent_ui/fluent_ui.dart' show ComboBoxItem, Text;
import 'package:momento_booth/exceptions/gphoto2_exception.dart';
import 'package:momento_booth/hardware_control/live_view_streaming/live_view_source.dart';
import 'package:momento_booth/hardware_control/photo_capturing/photo_capture_method.dart';
import 'package:momento_booth/main.dart';
import 'package:momento_booth/managers/settings_manager.dart';
import 'package:momento_booth/models/photo_capture.dart';
import 'package:momento_booth/src/rust/api/gphoto2.dart';
import 'package:momento_booth/src/rust/hardware_control/live_view/gphoto2.dart';
import 'package:momento_booth/src/rust/models/image_operations.dart';
import 'package:momento_booth/src/rust/models/images.dart';
import 'package:momento_booth/src/rust/models/live_view.dart';

class GPhoto2Camera extends PhotoCaptureMethod implements LiveViewSource {

  @override
  final String id;

  @override
  final String friendlyName;

  int? handleId;

  static Future<void>? _initFuture;

  GPhoto2Camera({required this.id, required this.friendlyName});

  static GPhoto2Camera fromCameraInfo(GPhoto2CameraInfo info) {
    return GPhoto2Camera(
      id: "${info.port}/${info.model}",
      friendlyName: "${info.model} (at ${info.port})",
    );
  }

  // //////////// //
  // List cameras //
  // //////////// //

  static Future<List<GPhoto2CameraInfo>> listCameras() async {
    await ensureLibraryInitialized();
    return await gphoto2GetCameras();
  }

  static Future<List<GPhoto2Camera>> getAllCameras() async {
    return (await listCameras()).map(GPhoto2Camera.fromCameraInfo).toList();
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
    await ensureLibraryInitialized();
    var split = id.split("/");
    handleId = await gphoto2OpenCamera(model: split[1], port: split[0], specialHandling: getIt<SettingsManager>().settings.hardware.gPhoto2SpecialHandling.toHelperLibraryEnumValue());
    await Future.delayed(Duration(seconds: 1));
    await gphoto2StartLiveview(handleId: handleId!, operations: operations, texturePtr: texturePtr);
    await Future.delayed(Duration(seconds: 1));

    gphoto2SetExtraFileCallback(handleId: handleId!).listen((element) {
      storePhotoSafe(element.filename, element.data);
    });
  }

  @override
  Future<void> setOperations(List<ImageOperation> operations) {
    return gphoto2SetOperations(handleId: handleId!, operations: operations);
  }

  @override
  Future<RawImage?> getLastFrame() async => handleId != null ? await gphoto2GetLastFrame(handleId: handleId!) : null;

  @override
  Future<CameraState> getCameraState() async => handleId != null
      ? gphoto2GetCameraStatus(handleId: handleId!)
      : const CameraState(
          isStreaming: false,
          validFrameCount: 0,
          errorFrameCount: 0,
          duplicateFrameCount: 0,
          lastFrameWasValid: false,
        );

  @override
  Future<void> dispose() async {
    if (handleId != null) {
      int handleId = this.handleId!;
      this.handleId = null; // Enforce that no more requests are fired to the camera to avoid panic.
      await gphoto2CloseCamera(handleId: handleId);
    }
  }

  @override
  Future<PhotoCapture> captureAndGetPhoto() async {
    String captureTarget = getIt<SettingsManager>().settings.hardware.gPhoto2CaptureTarget;
    if (handleId == null) throw GPhoto2Exception("Camera not open.");
    var capture = await gphoto2CapturePhoto(handleId: handleId!, captureTargetValue: captureTarget);
    await storePhotoSafe(capture.filename, capture.data);

    unawaited(clearPreviousEvents());

    return PhotoCapture(
      data: capture.data,
      filename: capture.filename,
    );
  }

  @override
  Duration get captureDelay => Duration(milliseconds: getIt<SettingsManager>().settings.hardware.captureDelayGPhoto2);

  Future<void> autoFocus() async {
    if (handleId != null) await gphoto2AutoFocus(handleId: handleId!);
  }

  @override
  Future<void> clearPreviousEvents() async {
    if (handleId != null) {
      await gphoto2ClearEvents(
        handleId: handleId!,
        downloadExtraFiles: getIt<SettingsManager>().settings.hardware.gPhoto2DownloadExtraFiles,
      );
    }
  }

  static Future<void> ensureLibraryInitialized() async {
    const String iolibsDefine = String.fromEnvironment("IOLIBS");
    const String camlibsDefine = String.fromEnvironment("CAMLIBS");
    _initFuture ??= gphoto2Initialize(iolibsPath: iolibsDefine, camlibsPath: camlibsDefine);
    await _initFuture;
  }

}
