import 'package:flutter/widgets.dart';
import 'package:momento_booth/views/base/screen_view_base.dart';
import 'package:momento_booth/views/gallery_screen/gallery_screen_controller.dart';
import 'package:momento_booth/views/gallery_screen/gallery_screen_view_model.dart';

class GalleryScreenView extends ScreenViewBase<GalleryScreenViewModel, GalleryScreenController> {

  const GalleryScreenView({
    required super.viewModel,
    required super.controller,
    required super.contextAccessor,
  });
  
  @override
  Widget get body {
    return Text("Hello from GalleryScreen!");
  }

}
