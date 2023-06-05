import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:momento_booth/views/base/screen_view_base.dart';
import 'package:momento_booth/views/custom_widgets/image_with_loader_fallback.dart';
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
    return Stack(
      children: [
        Observer(
          builder: (context) => GridView.count(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
            mainAxisSpacing: 20,
            crossAxisSpacing: 20,
            crossAxisCount: 4,
            children: [
              for (var file in viewModel.fileList)
                GestureDetector(
                  onTap: () => controller.openPhoto(file),
                  child: Hero(
                    tag: file.path,
                    child: Container(
                      decoration: const BoxDecoration(),
                      child: ImageWithLoaderFallback.file(file, fit: BoxFit.contain),
                    ),
                  ),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(30),
          child: Align(
            alignment: Alignment.bottomLeft,
            child: GestureDetector(
              onTap: controller.onPressedBack,
              child: AutoSizeText(
                "← Start",
                style: theme.subTitleStyle,
              ),
            ),
          ),
        ),
      ],
    );
  }

}
