import 'dart:ui';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_layout_grid/flutter_layout_grid.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_rust_bridge_example/managers/photos_manager.dart';
import 'package:flutter_rust_bridge_example/views/base/screen_view_base.dart';
import 'package:flutter_rust_bridge_example/views/collage_maker_screen/collage_maker_screen_controller.dart';
import 'package:flutter_rust_bridge_example/views/collage_maker_screen/collage_maker_screen_view_model.dart';
import 'package:flutter_rust_bridge_example/views/custom_widgets/photo_collage.dart';
import 'package:flutter/material.dart' show Icons;

class CollageMakerScreenView extends ScreenViewBase<CollageMakerScreenViewModel, CollageMakerScreenController> {

  const CollageMakerScreenView({
    required super.viewModel,
    required super.controller,
    required super.contextAccessor,
  });
  
  static const String _assetPath = "assets/bitmap/sample-background.jpg";
  
  @override
  Widget get body {
    return Stack(
      fit: StackFit.expand,
      children: [
        ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Image.asset(_assetPath, fit: BoxFit.cover),
        ),
        Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              flex: 2,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 30),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AutoSizeText("Pictures shot", style: theme.titleStyle,),
                    LayoutGrid(
                      areas: '''
                          content1 content2
                          content3 content4
                        ''',
                      rowSizes: [auto, auto],
                      columnSizes: [1.fr, 1.fr],
                      columnGap: 12,
                      rowGap: 12,
                      children: [
                        for (int i = 0; i < PhotosManagerBase.instance.photos.length; i++)
                          GestureDetector(
                            onTap: () => controller.togglePicture(i),
                            child: Observer(
                              builder: (BuildContext context) {
                                return Stack(
                                  children: [
                                    Image.memory(PhotosManagerBase.instance.photos[i]),
                                    AnimatedOpacity(
                                      opacity: PhotosManagerBase.instance.chosen.contains(i) ? 1 : 0,
                                      duration: Duration(milliseconds: 200),
                                      curve: Curves.easeInOut,
                                      child: Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          ColoredBox(color: Color(0x80000000)),
                                          Center(child: Icon(Icons.check, size: 80, color: Color(0xFFFFFFFF),),),
                                        ],
                                      ),
                                    )
                                  ],
                                );
                              }
                            ),
                          ).inGridArea('content${i+1}'),
                      ],
                    ),
                    Observer(
                      builder: (BuildContext context) { return AutoSizeText("${PhotosManagerBase.instance.chosen.length} chosen", style: theme.titleStyle,); },
                    ),
                  ],
                ),
              ),
            ),
            Flexible(
              flex: 3,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(child: AutoSizeText("Collage", style: theme.titleStyle,)),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(color: Color.fromARGB(255, 161, 161, 161)),
                      child: PhotoCollage(aspectRatio: 2/3)
                    ),
                  ),
                  Flexible(child: GestureDetector(
                    onTap: controller.onContinueTap,
                    child: AutoSizeText("Continue  →", style: theme.titleStyle,)
                  )),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

}
