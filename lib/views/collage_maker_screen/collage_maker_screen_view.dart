import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:flutter_rust_bridge_example/views/base/screen_view_base.dart';
import 'package:flutter_rust_bridge_example/views/collage_maker_screen/collage_maker_screen_controller.dart';
import 'package:flutter_rust_bridge_example/views/collage_maker_screen/collage_maker_screen_view_model.dart';

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
          children: [
            Flexible(child: Container(),),
            Flexible(child: Container(),),
          ],
        ),
      ],
    );
  }

}
