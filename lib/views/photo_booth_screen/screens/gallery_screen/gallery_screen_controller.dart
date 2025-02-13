import 'dart:convert';
import 'dart:io';

import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:http/http.dart' as http;
import 'package:momento_booth/main.dart';
import 'package:momento_booth/managers/settings_manager.dart';
import 'package:momento_booth/views/base/screen_controller_base.dart';
import 'package:momento_booth/views/components/dialogs/find_face_dialog.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/gallery_screen/gallery_screen_view_model.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/photo_details_screen/photo_details_screen.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/start_screen/start_screen.dart';
import 'package:path/path.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class GalleryScreenController extends ScreenControllerBase<GalleryScreenViewModel> {

  // Initialization/Deinitialization

  GalleryScreenController({
    required super.viewModel,
    required super.contextAccessor,
  });

  void openPhoto(File file) {
    final String filename = basename(file.path);
    logDebug("Opening photo $filename");
    router.push("${PhotoDetailsScreen.defaultRoute}/$filename");
  }

  void onPressedBack() {
    if (router.canPop()) {
      router.pop();
    } else {
      router.go(StartScreen.defaultRoute);
    }
  }

  Future<void> filterWithFaces() async {
    var baseUri = Uri.parse(getIt<SettingsManager>().settings.faceRecognition.serverUrl);
    try {
      var response = await http.get(baseUri.resolve("get-matching-imgs"));
      if (response.statusCode == 200) {
        var matchingImages = jsonDecode(response.body) as List<dynamic>?;
        var matchingImagesStrings = matchingImages!.cast<String>().toList();
        logDebug("Matching images: $matchingImagesStrings");
        viewModel.filterImages(matchingImagesStrings);
      } else {
        throw Exception("Failed to get matching images, status code: ${response.statusCode}");
      }
    } catch (e, s) {
      logError("Failed to get matching images: $e");
      await Sentry.captureException(e, stackTrace: s);
    }
  }

  void clearImageFilter() {
    viewModel..imageNames = null
             ..findImages();
  }

  void onFindMyFace() {
    showUserDialog(
      barrierDismissible: true,
      dialog: Observer(builder: (_) {
        return FindFaceDialog(
          title: 'Smile',
          onSuccess: () {
            navigator.pop();
            filterWithFaces();
          },
          onCancel: () => navigator.pop(),
        );
      }),
    );
  }

}
