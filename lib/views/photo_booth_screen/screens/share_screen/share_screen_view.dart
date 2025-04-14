import 'dart:math';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:confetti/confetti.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:momento_booth/views/base/screen_view_base.dart';
import 'package:momento_booth/views/components/imaging/image_with_loader_fallback.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/components/buttons/photo_booth_button.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/share_screen/share_screen_controller.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/share_screen/share_screen_view_model.dart';

class ShareScreenView extends ScreenViewBase<ShareScreenViewModel, ShareScreenController> {

  const ShareScreenView({
    required super.viewModel,
    required super.controller,
    required super.contextAccessor,
  });

  @override
  Widget get body {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Padding(
          padding: const EdgeInsets.all(30),
          child: Center(
            // This SizedBox is only necessary when the image used is smaller than what would be displayed.
            child: SizedBox(
              height: double.infinity,
              child: theme.captureCounterTheme.frameBuilder!(context, ImageWithLoaderFallback.memory(viewModel.outputImage, fit: BoxFit.contain)),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 30),
          child: _foregroundElements,
        ),
        if (viewModel.displayConfetti)
          ... _confettiStack,
      ],
    );
  }

  List<Widget> get _confettiStack {
    return [
      Align(
          alignment: Alignment.bottomLeft,
          child: _confetti(-0.25*pi, 45), // top right
        ),
        Align(
          alignment: Alignment.bottomLeft,
          child: _confetti(-0.325*pi, 42), // top right
        ),
        Align(
          alignment: Alignment.bottomLeft,
          child: _confetti(-0.4*pi, 30), // top right
        ),
        Align(
          alignment: Alignment.bottomRight,
          child: _confetti(-0.75*pi, 45), // top left
        ),
        Align(
          alignment: Alignment.bottomRight,
          child: _confetti(-0.675*pi, 42), // top left
        ),
        Align(
          alignment: Alignment.bottomRight,
          child: _confetti(-0.6*pi, 30), // top left
        ),
    ];
  }

  Widget _confetti(double direction, double force) {
    return ConfettiWidget(
      confettiController: viewModel.confettiController,
      blastDirection: direction,
      maximumSize: const Size(60, 30),
      minimumSize: const Size(40, 20),
      colors: viewModel.getColors(),
      minBlastForce: force,
      maxBlastForce: force*2,
      particleDrag: 0.01, // apply drag to the confetti
      emissionFrequency: 0.6, // how often it should emit
      numberOfParticles: 10, // number of particles to emit
      gravity: 0.3, // gravity - or fall speed
      shouldLoop: false,
      displayTarget: false,
    );
  }

  Widget get _foregroundElements {
    return Column(
      children: [
        Flexible(
          fit: FlexFit.tight,
          child: AutoSizeText(
            localizations.shareScreenTitle,
            style: theme.titleTheme.style,
          ),
        ),
        Expanded(
          flex: 3,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              PhotoBoothButton.navigation(
                onPressed: controller.onClickPrev,
                child: Row(
                  children: [
                    Icon(LucideIcons.stepBack),
                    Text(viewModel.backText),
                  ],
                ),
              ),
              PhotoBoothButton.navigation(
                onPressed: controller.onClickNext,
                child: Icon(LucideIcons.stepForward),
              ),
            ],
          ),
        ),
        Flexible(
          fit: FlexFit.tight,
          child: _getBottomRow(),
        ),
      ],
    );
  }

  Widget _getBottomRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        Flexible(
          child: PhotoBoothButton.action(
            onPressed: controller.onClickGetQR,
            title: localizations.photoDetailsScreenGetQrButton,
          ),
        ),
        Flexible(
          child: Observer(
            builder: (context) => PhotoBoothButton.action(
              onPressed: viewModel.printEnabled ? controller.onClickPrint : null,
              title: viewModel.printText,
            ),
          ),
        ),
      ],
    );
  }

}
