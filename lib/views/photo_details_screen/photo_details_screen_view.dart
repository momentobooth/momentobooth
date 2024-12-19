import 'package:auto_size_text/auto_size_text.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:momento_booth/views/base/screen_view_base.dart';
import 'package:momento_booth/views/base/settings_based_transition_page.dart';
import 'package:momento_booth/views/custom_widgets/image_with_loader_fallback.dart';
import 'package:momento_booth/views/custom_widgets/wrappers/delayed_widget.dart';
import 'package:momento_booth/views/photo_details_screen/photo_details_screen_controller.dart';
import 'package:momento_booth/views/photo_details_screen/photo_details_screen_view_model.dart';

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
                child: ImageWithLoaderFallback.file(viewModel.file, fit: BoxFit.contain),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 30),
          child: DelayedWidget(
            delay: SettingsBasedTransitionPage.defaultTransitionDuration,
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
          child: AutoSizeText(
            localizations.photoDetailsScreenTitle,
            style: theme.titleStyle,
          ),
        ),
        Expanded(
          flex: 3,
          child: Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              // Next button
              onTap: controller.onClickPrev,
              behavior: HitTestBehavior.translucent,
              child: AutoSizeText(
                " ← ${localizations.genericBackButton}",
                style: theme.subTitleStyle,
              ),
            ),
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
              child: AutoSizeText(
                localizations.photoDetailsScreenGetQrButton,
                style: theme.titleStyle,
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

}
