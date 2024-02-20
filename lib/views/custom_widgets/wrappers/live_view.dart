import 'dart:ui' as ui;
import 'dart:ui';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:momento_booth/managers/_all.dart';
import 'package:momento_booth/models/settings.dart';
import 'package:momento_booth/views/base/stateless_widget_base.dart';

class LiveView extends StatelessWidgetBase {

  final BoxFit fit;
  final bool blur;

  const LiveView({
    super.key,
    required this.fit,
    required this.blur,
  });

  ui.FilterQuality get _filterQuality => SettingsManager.instance.settings.ui.liveViewFilterQuality.toUiFilterQuality();
  int? get _textureId => LiveViewManager.instance.textureId;

  Rotate get _rotate => SettingsManager.instance.settings.hardware.liveViewAndCaptureRotate;
  Flip get _flip => SettingsManager.instance.settings.hardware.liveViewFlip;
  double get _aspectRatio => SettingsManager.instance.settings.hardware.liveViewAndCaptureAspectRatio;

  @override
  Widget build(BuildContext context) {
    Widget box = FittedBox(
      fit: fit,
      child: Observer(
        builder: (_) {
          return  Transform.flip(
            flipX: _flip == Flip.horizontally,
            flipY: _flip == Flip.vertically,
            child: RotatedBox(
              quarterTurns: _rotate.quarterTurns,
              child: SizedBox(
                  width: _aspectRatio,
                  height: 1,
                  child: _textureId != null
                      ? Texture(
                        textureId: _textureId!,
                        filterQuality: _filterQuality,
                      )
                      : null,
                ),
            ),
          );
        },
      ),
    );

    if (blur) {
      return ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: box,
      );
    } else {
      return box;
    }
  }

}
