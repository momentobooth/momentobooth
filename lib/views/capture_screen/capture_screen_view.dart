import 'dart:typed_data';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_rust_bridge_example/model/photo_state.dart';
import 'package:flutter_rust_bridge_example/views/base/screen_view_base.dart';
import 'package:flutter_rust_bridge_example/views/capture_screen/capture_screen_controller.dart';
import 'package:flutter_rust_bridge_example/views/capture_screen/capture_screen_view_model.dart';
import 'package:flutter_rust_bridge_example/views/custom_widgets/wrappers/sample_background.dart';

class CaptureScreenView extends ScreenViewBase<CaptureScreenViewModel, CaptureScreenController> {

  const CaptureScreenView({
    super.key,
    required super.viewModel,
    required super.controller,
    required super.contextAccessor,
  });
  
  @override
  Widget get body {
    
    return Stack(
      fit: StackFit.expand,
      children: [
        const SampleBackground(),
        Column(
          children: [
            Center(
              child: AutoSizeText(
                "Get Ready!",
                style: theme.titleStyle,
                maxLines: 1,
              ),
            ),
            FluentTheme(
              data: FluentThemeData(),
              child: Button(
                onPressed: controller.captureAndGetPhoto,
                child: Text("Capture photo")
              ),
            ),
            Expanded(
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 40.0),
                child: Observer(
                  builder: (context) {
                    Uint8List? imageData = PhotoStateBase.instance.photos.isNotEmpty ? PhotoStateBase.instance.photos.last : null;
                    if (imageData != null) {
                      return Image.memory(imageData);
                    } 
                    return SizedBox();
                  },
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

}
