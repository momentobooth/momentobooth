import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:momento_booth/theme/momento_booth_theme_data.dart';
import 'package:momento_booth/views/base/screen_view_base.dart';
import 'package:momento_booth/views/custom_widgets/wrappers/lottie_animation_wrapper.dart';
import 'package:momento_booth/views/start_screen/start_screen_controller.dart';
import 'package:momento_booth/views/start_screen/start_screen_view_model.dart';

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
          GestureDetector(
            onTap: controller.onPressedContinue,
            behavior: HitTestBehavior.opaque,
            child: _foregroundElements,
          ),
          Padding(
            padding: const EdgeInsets.all(30),
            child: Align(
              alignment: Alignment.bottomLeft,
              child: GestureDetector(
                onTap: controller.onPressedGallery,
                child: AutoSizeText(
                  localizations.startScreenGalleryButton,
                  style: theme.subTitleStyle,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget get _foregroundElements {
    return Column(
      children: [
        const Flexible(
          fit: FlexFit.tight,
          child: SizedBox(),
        ),
        Expanded(
          flex: 2,
          child: Center(
            child: AutoSizeText(
              localizations.startScreenTouchToStartButton,
              style: theme.titleStyle,
            ),
          ),
        ),
        Flexible(
          fit: FlexFit.tight,
          child: _getLogo(theme),
        ),
      ],
    );
  }

  Widget _getLogo(MomentoBoothThemeData themeData) {
    return SizedBox(
      width: 450,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 32),
        child: SvgPicture.asset(
          "assets/svg/logo.svg",
          colorFilter: ColorFilter.mode(themeData.defaultPageBackgroundColor, BlendMode.srcIn),
          alignment: Alignment.bottomCenter,
        ),
      ),
    );
  }

}
