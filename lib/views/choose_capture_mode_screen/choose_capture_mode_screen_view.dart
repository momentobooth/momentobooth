import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/widgets.dart';
import 'package:momento_booth/views/base/screen_view_base.dart';
import 'package:momento_booth/views/choose_capture_mode_screen/choose_capture_mode_screen_controller.dart';
import 'package:momento_booth/views/choose_capture_mode_screen/choose_capture_mode_screen_view_model.dart';

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
              "Choose Capture Mode",
              style: theme.titleStyle,
              maxLines: 1,
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Row(
            children: [
              Expanded(child: _singlePictureButton),
              const SizedBox(width: 32),
              Expanded(child: _collageButton),
            ],
          ),
        ),
        Flexible(
          fit: FlexFit.tight,
          child: const SizedBox(),
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
            "Single Picture",
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
                      SizedBox(width: 12),
                      _getButton(220),
                    ],
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      _getButton(220),
                      SizedBox(width: 12),
                      _getButton(220),
                    ],
                  ),
                ],
              ),
            ),
          ),
          AutoSizeText(
            "Collage",
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

}
