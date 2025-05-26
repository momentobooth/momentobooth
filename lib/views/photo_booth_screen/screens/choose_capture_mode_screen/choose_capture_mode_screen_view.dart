import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/widgets.dart';
import 'package:momento_booth/views/base/screen_view_base.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/choose_capture_mode_screen/choose_capture_mode_screen_controller.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/choose_capture_mode_screen/choose_capture_mode_screen_view_model.dart';

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
            child: AutoSizeText(
              localizations.chooseCaptureModeScreenTitle,
              style: theme.titleStyle,
              maxLines: 1,
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Row(
            spacing: 32,
            children: [
              Expanded(child: _singlePictureButton),
              Expanded(child: _collageButton),
              Expanded(child: _recordingButton),
            ],
          ),
        ),
        const Flexible(
          fit: FlexFit.tight,
          child: SizedBox(),
        ),
      ],
    );
  }

  Widget get _singlePictureButton {
    return GestureDetector(
      onTap: controller.onClickOnSinglePhoto,
      behavior: HitTestBehavior.translucent,
      child: Column(
        children: [
          Expanded(child: FittedBox(child: _getButton(452))),
          AutoSizeText(
            localizations.chooseCaptureModeScreenSinglePictureButton,
            group: viewModel.autoSizeGroup,
            style: theme.titleStyle,
            maxLines: 1,
          ),
        ],
      ),
    );
  }

  Widget get _collageButton {
    return GestureDetector(
      onTap: controller.onClickOnPhotoCollage,
      behavior: HitTestBehavior.translucent,
      child: Column(
        children: [
          Expanded(
            child: FittedBox(
              child: Column(
                children: [
                  Row(
                    children: [
                      _getButton(220),
                      const SizedBox(width: 12),
                      _getButton(220),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _getButton(220),
                      const SizedBox(width: 12),
                      _getButton(220),
                    ],
                  ),
                ],
              ),
            ),
          ),
          AutoSizeText(
            localizations.chooseCaptureModeScreenCollageButton,
            group: viewModel.autoSizeGroup,
            style: theme.titleStyle,
            maxLines: 1,
          ),
        ],
      ),
    );
  }

  Widget get _recordingButton {
    return GestureDetector(
      onTap: controller.onClickOnRecording,
      behavior: HitTestBehavior.translucent,
      child: Column(
        children: [
          Expanded(child: FittedBox(child: _getRoundButton(452))),
          AutoSizeText(
            "Recording",
            group: viewModel.autoSizeGroup,
            style: theme.titleStyle,
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
        color: theme.chooseCaptureModeButtonIconColor,
        boxShadow: [theme.chooseCaptureModeButtonShadow],
      ),
    );
  }

  Widget _getRoundButton(double dimension) {
    return Container(
      width: dimension,
      height: dimension,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(dimension),
        color: theme.chooseCaptureModeButtonIconColor,
        boxShadow: [theme.chooseCaptureModeButtonShadow],
      ),
    );
  }

}
