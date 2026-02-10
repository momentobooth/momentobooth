import 'dart:io';
import 'dart:ui';

import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:momento_booth/hardware_control/live_view_streaming/static_image_source.dart';
import 'package:momento_booth/main.dart';
import 'package:momento_booth/managers/settings_manager.dart';
import 'package:momento_booth/src/rust/api/images.dart';
import 'package:momento_booth/src/rust/models/image_operations.dart';
import 'package:momento_booth/src/rust/models/images.dart';
import 'package:momento_booth/src/rust/models/live_view.dart';
import 'package:path/path.dart';

class ServeFromDirSource extends StaticImageSource {

  int photoNumber = 0;
  int photosShown = 0;
  bool valid = true;
  late final BigInt texturePtr;

  String get serveFromDirectoryPath => getIt<SettingsManager>().settings.hardware.serveFromDirectoryPath;
  Directory get directory => Directory(serveFromDirectoryPath);

  late int _imageWidth, _imageHeight;

  File? currentlyDisplayedFile;
  RawImage? currentlyDisplayedImage;

  ServeFromDirSource();

  @override
  Future<void> openStream({
    required BigInt texturePtr,
    List<ImageOperation> operations = const [], // TODO: Implement
  }) async {
    this.texturePtr = texturePtr;
    await _getImage();
  }

  @override
  Future<RawImage> getLastFrame() => _getImage();

  @override
  Future<CameraState?> getCameraState() async => CameraState(
    isStreaming: true,
    validFrameCount: photosShown,
    errorFrameCount: 0,
    duplicateFrameCount: 0,
    lastFrameWasValid: valid,
    frameWidth: _imageWidth,
    frameHeight: _imageHeight,
  );


  Future<RawImage> _getImage() async {
    if (!directory.existsSync()) throw Exception("Directory $serveFromDirectoryPath does not exist");

    // Get list of image files
    final fileListBefore = await directory.list().toList();
    const validExtensions = ['.jpg', '.jpeg', '.png', '.bmp'];
    final matchingFiles = fileListBefore.whereType<File>().where((file) => validExtensions.contains(extension(file.path).toLowerCase())).toList();

    if (matchingFiles.isEmpty) {
      valid = false;
      throw Exception("No valid image files found in directory $serveFromDirectoryPath. Supported extensions: ${validExtensions.join(', ')}");
    }

    if (photoNumber >= matchingFiles.length) {
      photoNumber = 0;
    }
    var imgFile = File(join(directory.path, matchingFiles[photoNumber].path));
    currentlyDisplayedFile = imgFile;
    // Using modulo would be an option, but is less reliable when the number of files changes.
    photoNumber = (photoNumber + 1 == matchingFiles.length) ? 0 : photoNumber + 1;
    photosShown++;
  
    final Uint8List data = await imgFile.readAsBytes();
    final Image image = await decodeImageFromList(data);

    _imageWidth = image.width;
    _imageHeight = image.height;

    var imgData = (await image.toByteData())!.buffer.asUint8List();
    var rawImage = RawImage(
      format: RawImageFormat.rgba,
      width: image.width,
      height: image.height,
      data: imgData,
    );
    // If this is the first image, return it immediately. Otherwise, return the previously displayed image for capture.
    currentlyDisplayedImage ??= rawImage;
    var returnValue = currentlyDisplayedImage;
    currentlyDisplayedImage = rawImage;

    Future.delayed(const Duration(milliseconds: 1000), () async {
      // Show new image on live view texture.
      await staticImageWriteToTexture(
        texturePtr: texturePtr,
        rawImage: rawImage,
      );
    });
    return returnValue!;
  }

}
