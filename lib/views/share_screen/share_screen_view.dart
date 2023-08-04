import 'dart:math';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:momento_booth/managers/photos_manager.dart';
import 'package:momento_booth/views/base/screen_view_base.dart';
import 'package:momento_booth/views/custom_widgets/image_with_loader_fallback.dart';
import 'package:momento_booth/views/custom_widgets/wrappers/slider_widget.dart';
import 'package:momento_booth/views/share_screen/share_screen_controller.dart';
import 'package:momento_booth/views/share_screen/share_screen_view_model.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';

class ShareScreenView extends ScreenViewBase<ShareScreenViewModel, ShareScreenController> {

  const ShareScreenView({
    required super.viewModel,
    required super.controller,
    required super.contextAccessor,
  });
  
  @override
  Widget get body {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.all(30),
          child: Center(
            // This SizedBox is only necessary when the image used is smaller than what would be displayed.
            child: SizedBox(
              height: double.infinity,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F0F0),
                  border: theme.captureCounterContainerBorder,
                  boxShadow: [theme.captureCounterContainerShadow],
                ),
                child: ImageWithLoaderFallback.memory(viewModel.outputImage, fit: BoxFit.contain),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 30),
          child: _foregroundElements,
        ),
        if (viewModel.displayConfetti)
          ... _confettiStack,
        SizedBox.expand(child: _qrCodeBackdrop),
        _qrCode,
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
      minBlastForce: force,
      maxBlastForce: force*2,
      particleDrag: 0.01, // apply drag to the confetti
      emissionFrequency: 0.6, // how often it should emit
      numberOfParticles: 10, // number of particles to emit
      gravity: 0.3, // gravity - or fall speed
      shouldLoop: false,
      displayTarget: false,
      // colors: const [
      //   Colors.green,
      //   Colors.blue,
      //   Colors.pink
      // ], // manually specify the colors to be used
    );
  }

  Widget get _foregroundElements {
    return Column(
      children: [
        Flexible(
          fit: FlexFit.tight,
          child: AutoSizeText(
            localizations.shareScreenTitle,
            style: theme.titleStyle,
          ),
        ),
        Expanded(
          flex: 3,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GestureDetector(
                // Next button
                onTap: controller.onClickPrev,
                behavior: HitTestBehavior.translucent,
                child: AutoSizeText(
                  " ↺ ${viewModel.backText}",
                  style: theme.subTitleStyle,
                ),
              ),
              GestureDetector(
                // Next button
                onTap: controller.onClickNext,
                behavior: HitTestBehavior.translucent,
                child: AutoSizeText(
                  "→ ",
                  style: theme.titleStyle,
                ),
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
      children: [
        Flexible(
          child: Center(
            child: GestureDetector(
              // Get QR button
              onTap: controller.onClickGetQR,
              behavior: HitTestBehavior.translucent,
              child: Observer(
                builder: (context) => AutoSizeText(
                  viewModel.qrText,
                  style: theme.titleStyle,
                ),
              ),
            ),
          ),
        ),
        Flexible(
          child: GestureDetector(
            // Print button
            onTap: controller.onClickPrint,
            behavior: HitTestBehavior.translucent,
            child: Center(
              child: Observer(
                builder: (context) => AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: viewModel.printEnabled ? 1 : 0.5,
                  child: AutoSizeText(
                    viewModel.printText,
                    style: theme.titleStyle,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget get _qrCodeBackdrop {
    return Observer(builder: (_) {
      return IgnorePointer(
        ignoring: !viewModel.qrShown,
        child: GestureDetector(
          onTap: controller.onClickCloseQR,
          child: AnimatedOpacity(
            opacity: viewModel.qrShown ? 0.5 : 0.0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: const ColoredBox(color: Color(0xFF000000)),
          ),
        ),
      );
    });
  }

  Widget get _qrCode {
    return Observer(builder: (context) {
      return SliderWidget(
        key: viewModel.sliderKey,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xffffffff),
            borderRadius: BorderRadius.circular(10),
            border: theme.captureCounterContainerBorder,
            boxShadow: [theme.captureCounterContainerShadow],
          ),
          child: PrettyQr(
            size: 500,
            data: viewModel.qrUrl,
            errorCorrectLevel: QrErrorCorrectLevel.L,
            roundEdges: true,
          ),
        ),
      );
    });
  }

}
