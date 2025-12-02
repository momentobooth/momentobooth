import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:momento_booth/extensions/build_context_extension.dart';
import 'package:momento_booth/views/base/screen_view_base.dart';
import 'package:momento_booth/views/components/animations/lottie_animation_wrapper.dart';
import 'package:momento_booth/views/components/animations/repeating_indicator.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/start_screen/start_screen_controller.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/start_screen/start_screen_view_model.dart';

class StartScreenView extends ScreenViewBase<StartScreenViewModel, StartScreenController> {

  const StartScreenView({
    required super.viewModel,
    required super.controller,
    required super.contextAccessor,
  });

  @override
  Widget get body {
    return LottieAnimationWrapper(
      animationSettings: viewModel.introScreenLottieAnimations,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          RepeatingIndicator(
            lottieAsset: 'assets/animations/Animation - 1764508028194.json',
            cycleDuration: const Duration(seconds: 8),
            size: 300,
          ),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: controller.onPressedContinue,
              behavior: HitTestBehavior.opaque,
              child: _foregroundElements,
            ),
          ),
          Observer(
            builder: (context) {
              if (!viewModel.showSettingsButton) return const SizedBox.shrink();
              return Positioned(
                bottom: 0,
                right: 16,
                child: IconButton(
                  icon: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Icon(LucideIcons.cog, size: 64, color: Colors.white.withAlpha(64)),
                  ),
                  onPressed: controller.onPressedOpenSettings,
                ),
              );
            }
          ),
        ],
      ),
    );
  }

  Widget get _foregroundElements {
    const transparentWhite = Color.fromARGB(200, 255, 255, 255);
    final colorizeColors = [
      transparentWhite,
      const Color.fromARGB(255, 255, 156, 247),
      const Color.fromARGB(255, 148, 248, 252),
      transparentWhite,
    ];

    final colorizeTextStyle = context.theme.titleTheme.style;

    return Column(
      children: [
        const Flexible(fit: FlexFit.tight, child: SizedBox()),
        Expanded(
          flex: 2,
          child: Center(
            child: Observer(
              builder: (context) {
                final animatedTexts = viewModel.startTexts.map((text) {
                  return ColorizeAnimatedText(
                    text,
                    textStyle: colorizeTextStyle,
                    colors: colorizeColors,
                  );
                }).toList();
                return AnimatedTextKit(
                  repeatForever: true,
                  pause: viewModel.singleStartText ? const Duration(days: 9) : const Duration(seconds: 1),
                  onTap: controller.onPressedContinue,
                  animatedTexts: animatedTexts,
                );
              },
            ),
          ),
        ),
        Flexible(fit: FlexFit.tight, child: _logo),
      ],
    );
  }

  Widget get _logo {
    return SizedBox(
      width: 450,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 32),
        child: SvgPicture.asset(
          "assets/svg/logo.svg",
          colorFilter: ColorFilter.mode(Colors.white, BlendMode.srcIn),
          alignment: Alignment.bottomCenter,
        ),
      ),
    );
  }

}
