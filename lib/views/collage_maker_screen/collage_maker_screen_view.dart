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
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Flexible(
              flex: 2,
              child: _leftColumn
            ),
            Flexible(
              flex: 3,
              child: _rightColumn,
            ),
          ],
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 35, vertical: 10),
          child: Align(
            alignment: Alignment.bottomRight,
            child: GestureDetector(
              onTap: controller.onContinueTap,
              child: AutoSizeText("Continue  →", style: theme.subTitleStyle, maxLines: 1,)
            ),
          ),
        ),
      ],
    );
  }

  Widget get _leftColumn {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 30),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AutoSizeText("Pictures shot", style: theme.titleStyle, maxLines: 1,),
          _photoSelector,
          Observer(
            builder: (context) => AutoSizeText("${viewModel.numSelected} chosen", style: theme.titleStyle, maxLines: 1,),
          ),
        ],
      ),
    );
  }

  Widget get _photoSelector {
    return LayoutGrid(
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
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: AutoSizeText("Collage", style: theme.titleStyle,),
            )
          ),
          Expanded(
            flex: 10,
            child: _collage,
          ),
          Flexible(
            flex: 1,
            child: SizedBox()),
        ],
      ),
    );
  }

  Widget get _collage {
    return Observer(
      builder: (context) => AnimatedRotation(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        turns: -0.25 * viewModel.rotation,
        child: Container(
          decoration: BoxDecoration(
            color: Color.fromARGB(255, 255, 255, 255),
            boxShadow: [theme.chooseCaptureModeButtonShadow],
          ),
          child: PhotoCollage(
            key: controller.collageKey,
            aspectRatio: 2/3
          ),
        ),
      ),
    );
  }

}
