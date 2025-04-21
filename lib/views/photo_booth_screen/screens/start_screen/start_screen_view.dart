import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:momento_booth/views/base/screen_view_base.dart';
import 'package:momento_booth/views/components/animations/lottie_animation_wrapper.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/components/buttons/photo_booth_button.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/components/text/auto_size_text_and_icon.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/components/text/photo_booth_title.dart';
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
          GestureDetector(
            onTap: controller.onPressedContinue,
            behavior: HitTestBehavior.opaque,
            child: _foregroundElements,
          ),
          Padding(
            padding: const EdgeInsets.all(30),
            child: Align(
              alignment: Alignment.bottomLeft,
              child: PhotoBoothButton.navigation(
                onPressed: controller.onPressedGallery,
                child: AutoSizeTextAndIcon(text: localizations.startScreenGalleryButton),
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
        const Flexible(fit: FlexFit.tight, child: SizedBox()),
        Expanded(
          flex: 2,
          child: Center(
            child: Observer(
              builder: (context) => PhotoBoothTitle(
                viewModel.touchToStartText,
                textAlign: TextAlign.center,
                maxLines: null,
              ),
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
