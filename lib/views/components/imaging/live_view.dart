import 'dart:ui' as ui;
import 'dart:ui';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:momento_booth/main.dart';
import 'package:momento_booth/managers/_all.dart';
import 'package:momento_booth/models/settings.dart';
import 'package:momento_booth/views/components/imaging/rotate_flip_crop.dart';

class LiveView extends StatelessWidget {

  final BoxFit fit;
  final bool applyPostProcessing;
  final double blurSigma;

  const LiveView({
    super.key,
    required this.fit,
    this.applyPostProcessing = true,
    this.blurSigma = 0,
  });

  ui.FilterQuality get _filterQuality => getIt<SettingsManager>().settings.ui.liveViewFilterQuality.toUiFilterQuality();
  int? get _textureId => getIt<LiveViewManager>().textureId;

  Rotate get _rotate => getIt<SettingsManager>().settings.hardware.liveViewAndCaptureRotate;
  Flip get _flip => getIt<SettingsManager>().settings.hardware.liveViewFlip;
  double get _aspectRatio => getIt<SettingsManager>().settings.hardware.liveViewAndCaptureAspectRatio;

  @override
  Widget build(BuildContext context) {
    Widget box = FittedBox(
      fit: fit,
      child: Observer(
        builder: (_) {
          if (_textureId == null) return const SizedBox.shrink();

          Widget box = SizedBox(
            width: getIt<LiveViewManager>().textureWidth?.toDouble(),
            height: getIt<LiveViewManager>().textureHeight?.toDouble(),
            child: LayoutBuilder(
              builder: (context, boxConstraints) {
                // For some reason, we get unconstrained width and height when the application has just started.
                // This is a workaround to prevent errors.
                if (boxConstraints == const BoxConstraints()) return const SizedBox.shrink();
                return Texture(textureId: _textureId!, filterQuality: _filterQuality);
              }
            ),
          );

          if (applyPostProcessing) {
            return RotateFlipCrop(rotate: _rotate, flip: _flip, aspectRatio: _aspectRatio, child: box);
          } else {
            return box;
          }
        },
      ),
    );

    if (blurSigma > 0) {
      return ClipRect(
        // This is a (ugly? because I'd rather have a solution without LayoutBuilder...) way to fix the subtle
        // but noticeable black border around the background blur. It does so with respect to the aspect ratio
        // by finding the layout constraints, then calculating the size multiplier by looking at the shortest
        // side (we add 2 times the blur σ), then calculating the definitive size of the bleed box.
        child: LayoutBuilder(
          builder: (context, constraints) {
            double sizeMultiplier = (constraints.biggest.shortestSide + blurSigma * 2) / constraints.smallest.shortestSide;
            Size bleedBoxSize = constraints.biggest * sizeMultiplier;
            return OverflowBox(
              minWidth: bleedBoxSize.width,
              maxWidth: bleedBoxSize.width,
              minHeight: bleedBoxSize.height,
              maxHeight: bleedBoxSize.height,
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
                child: box,
              ),
            );
          }
        ),
      );
    } else {
      return box;
    }
  }

}
