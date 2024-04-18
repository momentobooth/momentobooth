import 'dart:convert';
import 'dart:io';

import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:http/http.dart' as http;
import 'package:loggy/loggy.dart';
import 'package:momento_booth/views/base/screen_controller_base.dart';
import 'package:momento_booth/views/custom_widgets/dialogs/find_face_dialog.dart';
import 'package:momento_booth/views/gallery_screen/gallery_screen_view_model.dart';
import 'package:momento_booth/views/photo_details_screen/photo_details_screen.dart';
import 'package:path/path.dart';

class GalleryScreenController extends ScreenControllerBase<GalleryScreenViewModel> with UiLoggy {

  // Initialization/Deinitialization

  GalleryScreenController({
    required super.viewModel,
    required super.contextAccessor,
  });

  void openPhoto(File file) {
    final String filename = basename(file.path);
    loggy.debug("Opening photo $filename");
    router.push("${PhotoDetailsScreen.defaultRoute}/$filename");
  }

  void onPressedBack() {
    router.pop();
  }

  Future<void> filterWithFaces() async {
    var response = await http.get(Uri.parse("http://localhost:3232/get-matching-imgs"));
    if (response.statusCode == 200) {
      var matchingImages = jsonDecode(response.body) as List<dynamic>?;
      var matchingImagesStrings = matchingImages!.cast<String>().toList();
      loggy.debug("Matching images: $matchingImagesStrings");
      viewModel.filterImages(matchingImagesStrings);
    } else {
      loggy.warning("Error getting matching face images: ${response.body}");
    }
  }

  void clearImageFilter() {
    viewModel..imageNames = null
             ..findImages();
  }

  void onFindMyFace() {
    showUserDialog(
      barrierDismissible: false,
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
