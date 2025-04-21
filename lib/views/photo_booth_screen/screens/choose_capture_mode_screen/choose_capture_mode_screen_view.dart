import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/widgets.dart';
import 'package:momento_booth/views/base/screen_view_base.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/choose_capture_mode_screen/choose_capture_mode_screen_controller.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/choose_capture_mode_screen/choose_capture_mode_screen_view_model.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/components/buttons/photo_booth_button.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/components/text/photo_booth_title.dart';

class ChooseCaptureModeScreenView extends ScreenViewBase<ChooseCaptureModeScreenViewModel, ChooseCaptureModeScreenController> {

  const ChooseCaptureModeScreenView({
    required super.viewModel,
    required super.controller,
    required super.contextAccessor,
  });

  @override
  Widget get body {
    return Column(
      children: [
        Flexible(
          fit: FlexFit.tight,
          child: Center(
            child: PhotoBoothTitle(localizations.chooseCaptureModeScreenTitle),
          ),
        ),
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 64),
            child: Row(
              spacing: 32,
              children: [
                Expanded(child: _singlePictureButton),
                Expanded(child: _collageButton),
              ],
            ),
          ),
        ),
        const Flexible(fit: FlexFit.tight, child: SizedBox()),
      ],
    );
  }

  Widget get _singlePictureButton {
    return PhotoBoothButton.action(
      onPressed: controller.onClickOnSinglePhoto,
      child: Column(
        spacing: 16,
        children: [
          Expanded(child: FittedBox(child: _getButton(452))),
          AutoSizeText(
            localizations.chooseCaptureModeScreenSinglePictureButton,
            group: controller.autoSizeGroup,
            maxLines: 1,
          ),
        ],
      ),
    );
  }

  Widget get _collageButton {
    return PhotoBoothButton.action(
      onPressed: controller.onClickOnPhotoCollage,
      child: Column(
        spacing: 16,
        children: [
          Expanded(
            child: FittedBox(
              child: Column(
                spacing: 12,
                children: [
                  Row(
                    spacing: 12,
                    children: [_getButton(220), _getButton(220)],
                  ),
                  Row(
                    spacing: 12,
                    children: [_getButton(220), _getButton(220)],
                  ),
                ],
              ),
            ),
          ),
          AutoSizeText(
            localizations.chooseCaptureModeScreenCollageButton,
            group: controller.autoSizeGroup,
            maxLines: 1,
          ),
        ],
      ),
    );
  }

  Widget _getButton(double dimension) {
    return Container(
      width: dimension,
      height: dimension,
      decoration: BoxDecoration(
        color: const Color(0xE6FFFFFF),
        boxShadow: [const BoxShadow(
          color: Color(0x42000000),
          offset: Offset(0, 3),
          blurRadius: 8,
        )],
      ),
    );
  }

}
