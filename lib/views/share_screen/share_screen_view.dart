import 'dart:ui';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_rust_bridge_example/extensions/build_context_extension.dart';
import 'package:flutter_rust_bridge_example/theme/momento_booth_theme_data.dart';
import 'package:flutter_rust_bridge_example/views/base/screen_view_base.dart';
import 'package:flutter_rust_bridge_example/views/custom_widgets/wrappers/sample_background.dart';
import 'package:flutter_rust_bridge_example/views/share_screen/share_screen_controller.dart';
import 'package:flutter_rust_bridge_example/views/share_screen/share_screen_view_model.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:qr/qr.dart';

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
        _qrCode
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

  Widget get _qrCode {
    return Observer(builder: (context) {
      if (viewModel.uploadState != UploadState.done) {
        return SizedBox();
      }
      return SliderWidget(
        child: Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Color(0xffffffff),
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

class SliderWidget extends StatefulWidget {
  final Widget child; 

  const SliderWidget({
    super.key,
    required this.child,
  });

  @override
  State<SliderWidget> createState() => _SliderWidgetState();
}

class _SliderWidgetState extends State<SliderWidget>
    with SingleTickerProviderStateMixin {

  late final AnimationController _controller = AnimationController(
    duration: const Duration(milliseconds: 600),
    vsync: this,
  )..forward();
  
  late final Animation<Offset> _offsetAnimation = Tween<Offset>(
    begin: const Offset(0.0, 1.5),
    end: Offset.zero,
  ).animate(CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOut,
  ));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _offsetAnimation,
      child: Padding(
        padding: EdgeInsets.all(8.0),
        child: Padding(
          padding: EdgeInsets.all(30),
          child: Center(
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
