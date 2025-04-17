import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:momento_booth/views/base/screen_view_base.dart';
import 'package:momento_booth/views/base/transition_page.dart';
import 'package:momento_booth/views/components/animations/animated_delayed_fade_in.dart';
import 'package:momento_booth/views/components/imaging/image_with_loader_fallback.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/components/buttons/photo_booth_button.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/components/text/auto_size_text_and_icon.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/components/text/photo_booth_title.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/photo_details_screen/photo_details_screen_controller.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/photo_details_screen/photo_details_screen_view_model.dart';

class PhotoDetailsScreenView extends ScreenViewBase<PhotoDetailsScreenViewModel, PhotoDetailsScreenController> {

  const PhotoDetailsScreenView({
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
              child: Hero(
                tag: viewModel.file!.path,
                child: ImageWithLoaderFallback.file(viewModel.file!, fit: BoxFit.contain),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 30),
          child: AnimatedDelayedFadeIn(
            delay: TransitionPage.defaultTransitionDuration,
            child: _foregroundElements,
          ),
        ),
      ],
    );
  }

  Widget get _foregroundElements {
    return Column(
      children: [
        Flexible(
          fit: FlexFit.tight,
          child: PhotoBoothTitle(localizations.photoDetailsScreenTitle),
        ),
        Expanded(
          flex: 3,
          child: Align(
            alignment: Alignment.centerLeft,
            child: PhotoBoothButton.navigation(
              onPressed: controller.onClickPrev,
              child: AutoSizeTextAndIcon(text: localizations.genericBackButton, leftIcon: LucideIcons.stepBack),
            ),
          ),
        ),
        Flexible(fit: FlexFit.tight, child: _getBottomRow()),
      ],
    );
  }

  Widget _getBottomRow() {
    return Row(
      children: [
        Flexible(
          child: Center(
            child: PhotoBoothButton.action(
              onPressed: controller.onClickGetQR,
              child: AutoSizeTextAndIcon(
                text: localizations.photoDetailsScreenGetQrButton,
                leftIcon: LucideIcons.scanQrCode,
              ),
            ),
          ),
        ),
        Flexible(
          child: Center(
            child: Observer(
              builder: (context) => PhotoBoothButton.action(
                onPressed: viewModel.printEnabled ? controller.onClickPrint : null,
                child: AutoSizeTextAndIcon(
                  text: viewModel.printText,
                  leftIcon: LucideIcons.printer,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

}
