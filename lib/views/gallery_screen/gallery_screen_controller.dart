import 'dart:io';

import 'package:flutter_mobx/flutter_mobx.dart';
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

  void onFindMyFace() {
    showUserDialog(
      barrierDismissible: false,
      dialog: Observer(builder: (_) {
        return FindFaceDialog(
          title: 'Smile',
          onDismiss: () => navigator.pop(),
          onCancel: () => navigator.pop(),
        );
      }),
    );
  }

}
