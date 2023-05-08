import 'dart:io';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:momento_booth/managers/photos_manager.dart';
import 'package:momento_booth/views/base/screen_view_base.dart';
import 'package:momento_booth/views/custom_widgets/image_with_loader_fallback.dart';
import 'package:momento_booth/views/custom_widgets/photo_collage.dart';
import 'package:momento_booth/views/manual_collage_screen/manual_collage_screen_controller.dart';
import 'package:momento_booth/views/manual_collage_screen/manual_collage_screen_view_model.dart';

class ManualCollageScreenView extends ScreenViewBase<ManualCollageScreenViewModel, ManualCollageScreenController> {

  const ManualCollageScreenView({
    required super.viewModel,
    required super.controller,
    required super.contextAccessor,
  });
  
  @override
  Widget get body {
    return Row(
      children: [
        Flexible(child: _photoGrid),
        Flexible(
          fit: FlexFit.tight,
          child: _rightColumn
        ),
      ],
    );
  }

  Widget _photoInst(File file, int i) {
    return Observer(
      builder: (BuildContext context) {
        return Stack(
          children: [
            ImageWithLoaderFallback.file(file, fit: BoxFit.contain),
            AnimatedOpacity(
              opacity: PhotosManagerBase.instance.chosen.contains(i) ? 1 : 0,
              duration: Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ColoredBox(color: Color(0x80000000)),
                  Center(
                    child: Text((PhotosManagerBase.instance.chosen.indexOf(i)+1).toString(), style: theme.subTitleStyle,),
                  ),
                ],
              ),
            )
          ],
        );
      }
    );
  }

  Widget get _photoGrid {
    return Observer(
      builder: (context) => GridView.count(
        padding: EdgeInsets.symmetric(horizontal: 30, vertical: 10),
        mainAxisSpacing: 20,
        crossAxisSpacing: 20,
        crossAxisCount: 4,
        childAspectRatio: 1.5,
        children: [
          for (var file in viewModel.fileList)
            GestureDetector(
              onTap: () => controller.tapPhoto(file),
              child: _photoInst(file, 0),
            ),
        ],
      ),
    );
  }

  Widget get _rightColumn {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        children: [
          Flexible(
            flex: 1,
            child: SizedBox()
          ),
          Expanded(
            flex: 10,
            child: _collage,
          ),
          Flexible(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GestureDetector(
                onTap: controller.captureCollage,
                child: AutoSizeText("Save", style: theme.titleStyle,)
              ),
            )
          ),
        ],
      ),
    );
  }

  Widget get _collage {
    return Observer(
      builder: (context) => AnimatedRotation(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        turns: -0.25 * viewModel.rotation, // could also use controller.collageKey.currentState!.rotation
        child: Container(
          decoration: BoxDecoration(
            color: Color.fromARGB(255, 255, 255, 255),
            boxShadow: [theme.chooseCaptureModeButtonShadow],
          ),
          child: FittedBox(
            child: PhotoCollage(
              key: controller.collageKey,
              aspectRatio: 1/viewModel.collageAspectRatio,
              padding: viewModel.collagePadding,
            ),
          ),
        ),
      ),
    );
  }

}
