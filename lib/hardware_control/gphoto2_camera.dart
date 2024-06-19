
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
import 'package:momento_booth/src/rust/models/images.dart';
import 'package:momento_booth/src/rust/models/live_view.dart';
import 'package:momento_booth/src/rust/utils/image_processing.dart';

class GPhoto2Camera extends PhotoCaptureMethod implements LiveViewSource {

  @override
  final String id;

  @override
  final String friendlyName;

  int? handleId;
  bool isDisposed = false;

  static Future<void>? _initFuture;

  GPhoto2Camera({required this.id, required this.friendlyName});

  // //////////// //
  // List cameras //
  // //////////// //

  static Future<List<GPhoto2Camera>> getAllCameras() async {
    await _ensureLibraryInitialized();
    List<GPhoto2CameraInfo> cameras = await gphoto2GetCameras();
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
  Future<void> openStream({
    required BigInt texturePtr,
    List<ImageOperation> operations = const [],
  }) async {
    await _ensureLibraryInitialized();
    var split = id.split("/");
    handleId = await gphoto2OpenCamera(model: split[1], port: split[0], specialHandling: getIt<SettingsManager>().settings.hardware.gPhoto2SpecialHandling.toHelperLibraryEnumValue());
    await gphoto2StartLiveview(
      handleId: handleId!,
      operations: operations,
      texturePtr: texturePtr,
    );

    // Do this in case someone disposed while we where waiting for the async camera open.
    if (isDisposed) await dispose();

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
    if (handleId != null) await gphoto2CloseCamera(handleId: handleId!);
    isDisposed = true;
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
    await _ensureLibraryInitialized();
    if (handleId != null) await gphoto2AutoFocus(handleId: handleId!);
  }

  @override
  Future<void> clearPreviousEvents() async {
    await _ensureLibraryInitialized();
    if (handleId != null) {
      await gphoto2ClearEvents(
        handleId: handleId!,
        downloadExtraFiles: getIt<SettingsManager>().settings.hardware.gPhoto2DownloadExtraFiles,
      );
    }
  }

  static Future<void> _ensureLibraryInitialized() async {
    const String iolibsDefine = String.fromEnvironment("IOLIBS");
    const String camlibsDefine = String.fromEnvironment("CAMLIBS");
    _initFuture ??= gphoto2Initialize(iolibsPath: iolibsDefine, camlibsPath: camlibsDefine);
    await _initFuture;
  }

}
