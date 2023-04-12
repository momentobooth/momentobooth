import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_rust_bridge_example/managers/photos_manager.dart';
import 'package:flutter_rust_bridge_example/managers/settings_manager.dart';
import 'package:flutter_rust_bridge_example/views/base/screen_controller_base.dart';
import 'package:flutter_rust_bridge_example/views/collage_maker_screen/collage_maker_screen_view_model.dart';
import 'package:flutter_rust_bridge_example/views/custom_widgets/photo_collage.dart';

class CollageMakerScreenController extends ScreenControllerBase<CollageMakerScreenViewModel> {

  // Initialization/Deinitialization

  CollageMakerScreenController({
    required super.viewModel,
    required super.contextAccessor,
  });

  /// Global key for controlling the slider widget.
  GlobalKey<PhotoCollageState> collageKey = GlobalKey<PhotoCollageState>();

  void togglePicture(int image) {
    if (PhotosManagerBase.instance.chosen.contains(image)) {
      PhotosManagerBase.instance.chosen.remove(image);
    } else {
      PhotosManagerBase.instance.chosen.add(image);
    }
    captureCollage();
  }

  String get outputFolder => SettingsManagerBase.instance.settings.output.localFolder;

  void captureCollage() async {
    final stopwatch = Stopwatch()..start();
    PhotosManagerBase.instance.outputImage = await collageKey.currentState!.getCollageImage();
    print('captureCollage() executed in ${stopwatch.elapsed}');
    print("Written collage image to output image memory");
    File file = await File('$outputFolder/MomentoBooth-image.jpg').create();
    await file.writeAsBytes(PhotosManagerBase.instance.outputImage!);
  }

  void onContinueTap() {
    // Todo: a whole lot of stuff
    router.push("/share");
  }

}
