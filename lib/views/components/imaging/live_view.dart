import 'dart:io';
import 'dart:ui' as ui;
import 'dart:ui';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:momento_booth/main.dart';
import 'package:momento_booth/managers/_all.dart';
import 'package:momento_booth/models/settings.dart';
import 'package:momento_booth/models/template_kind.dart';
import 'package:momento_booth/views/components/imaging/rotate_flip_crop.dart';

class LiveView extends StatefulWidget {

  /// The BoxFit to use for the live view image.
  final BoxFit fit;
  /// Whether to apply transformations (rotation, flipping, cropping) to the live view image.
  final bool applyPostProcessing;
  /// Whether to show the overlay image on top of the live view.
  /// It is shown for the "front layer" of the live view background, not the blurry "back layer".
  /// An overlay is only displayed if an overlay image template exists.
  final bool showOverlay;
  /// The σ (sigma) value for the Gaussian blur applied to the live view, for the blurry "back layer".
  final double blurSigma;

  const LiveView({
    super.key,
    required this.fit,
    this.applyPostProcessing = true,
    this.showOverlay = false,
    this.blurSigma = 0,
  });

  @override
  State<LiveView> createState() => _LiveViewState();

}

class _LiveViewState extends State<LiveView> with SingleTickerProviderStateMixin {

  late AnimationController _aspectRatioController;
  late Animation<double> _aspectRatioAnimation;

  // Store the actual begin and end values for the tween
  double _animationBegin = 0.0;
  double _animationEnd = 0.0;

  @override
  void initState() {
    super.initState();
    _aspectRatioController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _animationBegin = _getCurrentTargetAspectRatio();
    _animationEnd = _animationBegin; // Start with the same value

    _aspectRatioAnimation = _aspectRatioController
        .drive(CurveTween(curve: Curves.ease))
        .drive(Tween<double>(begin: _animationBegin, end: _animationEnd));
  }

  // Helper function to get the target aspect ratio based on current state
  double _getCurrentTargetAspectRatio() {
    if (getIt<LiveViewManager>().isRecordingLayout) {
      return 16 / 9;
    } else {
      return getIt<SettingsManager>().settings.hardware.liveViewAndCaptureAspectRatio;
    }
  }

  ui.FilterQuality get _filterQuality => getIt<SettingsManager>().settings.ui.liveViewFilterQuality.toUiFilterQuality();
  int? get _textureId => getIt<LiveViewManager>().textureId;

  Rotate get _rotate => getIt<SettingsManager>().settings.hardware.liveViewAndCaptureRotate;
  Flip get _flip => getIt<SettingsManager>().settings.hardware.liveViewFlip;

  @override
  Widget build(BuildContext context) {
    File? overlayImage = getIt<ProjectManager>().templates[TemplateKind.liveViewOverlay]?[0];
    Widget box = FittedBox(
      fit: widget.fit,
      child: Observer(
        builder: (_) {
          if (_textureId == null) return const SizedBox.shrink();

          Widget textureBox = SizedBox(
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

          Widget lvImage = textureBox;
          if (widget.applyPostProcessing) {
            final double targetAspectRatio = _getCurrentTargetAspectRatio();

            // If the target aspect ratio has changed, update the Tween and start the animation
            if (_animationEnd != targetAspectRatio) {
              _animationBegin = _aspectRatioAnimation.value; // Start from current animated value
              _animationEnd = targetAspectRatio;

              // Re-drive the animation with new begin/end values
              _aspectRatioAnimation = _aspectRatioController
                  .drive(CurveTween(curve: Curves.ease))
                  .drive(Tween<double>(begin: _animationBegin, end: _animationEnd));

              _aspectRatioController.forward(from: 0); // Start the animation
            }

            lvImage = AnimatedBuilder(
              animation: _aspectRatioAnimation,
              builder: (context, child) {
                return RotateFlipCrop(
                  rotate: _rotate,
                  flip: _flip,
                  aspectRatio: _aspectRatioAnimation.value, // Use the animated value
                  child: textureBox,
                );
              },
            );
          }

          // When an overlay image template exists and the showOverlay flag is true, we stack the live view image with the overlay image.
          if (overlayImage != null && widget.showOverlay) {
            return Stack(
              fit: StackFit.passthrough,
              children: [
                lvImage,
                Positioned.fill(child: Image.file(overlayImage, fit: BoxFit.cover)),
              ],
            );
          } else {
            return lvImage;
          }
        },
      ),
    );

    if (widget.blurSigma > 0) {
      return ClipRect(
        // This is a (ugly? because I'd rather have a solution without LayoutBuilder...) way to fix the subtle
        // but noticeable black border around the background blur. It does so with respect to the aspect ratio
        // by finding the layout constraints, then calculating the size multiplier by looking at the shortest
        // side (we add 2 times the blur σ), then calculating the definitive size of the bleed box.
        child: LayoutBuilder(
          builder: (context, constraints) {
            double sizeMultiplier = (constraints.biggest.shortestSide + widget.blurSigma * 2) / constraints.smallest.shortestSide;
            Size bleedBoxSize = constraints.biggest * sizeMultiplier;
            return OverflowBox(
              minWidth: bleedBoxSize.width,
              maxWidth: bleedBoxSize.width,
              minHeight: bleedBoxSize.height,
              maxHeight: bleedBoxSize.height,
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: widget.blurSigma, sigmaY: widget.blurSigma),
                child: box,
              ),
            );
          },
        ),
      );
    } else {
      return box;
    }
  }

  @override
  void dispose() {
    _aspectRatioController.dispose();
    super.dispose();
  }

}
