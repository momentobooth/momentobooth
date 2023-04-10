import 'dart:ui';

import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_rust_bridge_example/managers/photos_manager.dart';
import 'package:flutter_rust_bridge_example/views/base/screen_view_base.dart';
import 'package:flutter_rust_bridge_example/views/multi_capture_screen/multi_capture_screen_controller.dart';
import 'package:flutter_rust_bridge_example/views/multi_capture_screen/multi_capture_screen_view_model.dart';
import 'package:flutter_rust_bridge_example/views/custom_widgets/capture_counter.dart';

class MultiCaptureScreenView extends ScreenViewBase<MultiCaptureScreenViewModel, MultiCaptureScreenController> {

  const MultiCaptureScreenView({
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
            Flexible(
              flex: 1,
              child: Column(
                children: [
                  Flexible(child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: AutoSizeText("Photo ${viewModel.photoNumber}/${viewModel.maxPhotos}", style: theme.titleStyle, maxLines: 1,),
                  )),
                  for (int i = 0; i < PhotosManagerBase.instance.photos.length; i++)
                    Flexible(
                      flex: 0,
                      child: Padding(padding: EdgeInsets.symmetric(vertical: 10),
                        child: AspectRatio(
                          aspectRatio: 1.5,
                          child: Image.memory(PhotosManagerBase.instance.photos[i])
                        ),
                      ),
                    ),
                  for (int i = PhotosManagerBase.instance.photos.length; i < 4; i++)
                    Flexible(
                      flex: 0,
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        child: AspectRatio(
                          aspectRatio: 1.5,
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              border: theme.captureCounterContainerBorder,
                              // boxShadow: [theme.captureCounterContainerShadow],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Flexible(
              flex: 5,
              child: AspectRatio(
                aspectRatio: 1.5,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(_assetPath, fit: BoxFit.contain),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _getReadyText,
                        Flexible(child: Container(
                          padding: EdgeInsets.all(40.0),
                          constraints: BoxConstraints(maxWidth: 600, maxHeight: 600),
                          child: Observer(builder: (_) {
                            return AnimatedOpacity(
                              duration: Duration(milliseconds: 50),
                              opacity: viewModel.showCounter ? 1.0 : 0.0,
                              child: CaptureCounter(
                                onCounterFinished: viewModel.onCounterFinished,
                                counterStart: viewModel.counterStart,),
                            );
                          })
                        )),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        _flashAnimation
      ],
    );
  }

  Widget get _getReadyText {
    return Center(
      child: SizedBox(
        height: 300,
        child: AnimatedTextKit(
                pause: Duration(milliseconds: viewModel.counterStart >= 3 ? 1000 : 0),
                isRepeatingAnimation: false,
                animatedTexts: [
                    RotateAnimatedText("Get Ready!", textStyle: theme.titleStyle, duration: Duration(milliseconds: 1000)),
                    RotateAnimatedText("Look at 📷", textStyle: theme.titleStyle, duration: Duration(milliseconds: 1000)),
                ],
              ),
      ),
    );
  }

  Widget get _flashAnimation {
    return Observer(builder: (_) {
      return AnimatedOpacity(
        opacity: viewModel.opacity,
        duration: viewModel.flashAnimationDuration,
        curve: viewModel.flashAnimationCurve,
        child: ColoredBox(color: Color(0xFFFFFFFF)),
      );
    });
  }

}
