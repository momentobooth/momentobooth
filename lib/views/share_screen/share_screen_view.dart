import 'dart:ui';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_rust_bridge_example/theme/momento_booth_theme_data.dart';
import 'package:flutter_rust_bridge_example/views/base/screen_view_base.dart';
import 'package:flutter_rust_bridge_example/views/custom_widgets/wrappers/sample_background.dart';
import 'package:flutter_rust_bridge_example/views/share_screen/share_screen_controller.dart';
import 'package:flutter_rust_bridge_example/views/share_screen/share_screen_view_model.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ShareScreenView extends ScreenViewBase<ShareScreenViewModel, ShareScreenController> {

  const ShareScreenView({
    required super.viewModel,
    required super.controller,
    required super.contextAccessor,
  });

  static const String _assetPath = "assets/bitmap/sample-background.jpg";
  
  @override
  Widget get body {
    return Stack(
      fit: StackFit.expand,
      children: [
        ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Image.asset(_assetPath, fit: BoxFit.cover),
        ),
        Padding(
          padding: EdgeInsets.all(30),
          child: Center(
            child: Container(
              decoration: BoxDecoration(
                border: theme.captureCounterContainerBorder,
                boxShadow: [theme.captureCounterContainerShadow],
              ),
              child: AspectRatio(
                aspectRatio: 1.5,
                child: Image.asset(_assetPath, fit: BoxFit.contain)
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 30),
          child: _foregroundElements,
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
            "Share",
            style: theme.titleStyle,
          ),
        ),
        Expanded(
          flex: 3,
          child: Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              // Next button
              onTap: controller.onClickNext,
              behavior: HitTestBehavior.translucent,
              child: AutoSizeText(
                "→ ",
                style: theme.titleStyle,
              ),
            ),
          ),
        ),
        Flexible(
          fit: FlexFit.tight,
          child: _getBottomRow(theme),
        ),
      ],
    );
  }

  Widget _getBottomRow(MomentoBoothThemeData themeData) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        Flexible(
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
        Flexible(
          child: GestureDetector(
            // Print button
            onTap: controller.onClickPrint,
            behavior: HitTestBehavior.translucent,
            child: AutoSizeText(
              "Print",
              style: theme.titleStyle,
            ),
          ),
        ),
      ],
    );
  }

}
