import 'dart:ui';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:momento_booth/extensions/build_context_extension.dart';
import 'package:momento_booth/theme/momento_booth_theme_data.dart';
import 'package:momento_booth/views/base/screen_view_base.dart';
import 'package:momento_booth/views/share_screen/share_screen_controller.dart';
import 'package:momento_booth/views/share_screen/share_screen_view_model.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';

class ShareScreenView extends ScreenViewBase<ShareScreenViewModel, ShareScreenController> {

  const ShareScreenView({
    required super.viewModel,
    required super.controller,
    required super.contextAccessor,
  });
  
  @override
  Widget get body {
    return Stack(
      children: [
        Padding(
          padding: EdgeInsets.all(30),
          child: Center(
            // This SizedBox is only necessary when the image used is smaller than what would be displayed.
            child: SizedBox(
              height: double.infinity,
              child: Container(
                decoration: BoxDecoration(
                  color: Color(0xFFF0F0F0),
                  border: theme.captureCounterContainerBorder,
                  boxShadow: [theme.captureCounterContainerShadow],
                ),
                child: Image.memory(viewModel.outputImage, fit: BoxFit.contain),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 30),
          child: _foregroundElements,
        ),
        SizedBox.expand(child: _qrCodeBackdrop),
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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GestureDetector(
                // Next button
                onTap: controller.onClickPrev,
                behavior: HitTestBehavior.translucent,
                child: AutoSizeText(
                  " ↺ ${viewModel.backText}",
                  style: theme.subTitleStyle,
                ),
              ),
              GestureDetector(
                // Next button
                onTap: controller.onClickNext,
                behavior: HitTestBehavior.translucent,
                child: AutoSizeText(
                  "→ ",
                  style: theme.titleStyle,
                ),
              ),
            ],
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

  Widget get _qrCodeBackdrop {
    return Observer(builder: (_) {
      return IgnorePointer(
        ignoring: !viewModel.qrShown,
        child: GestureDetector(
          onTap: controller.onClickCloseQR,
          child: AnimatedOpacity(
            opacity: viewModel.qrShown ? 0.5 : 0.0,
            duration: Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: ColoredBox(color: Color(0xFF000000)),
          ),
        ),
      );
    });
  }

  Widget get _qrCode {
    return Observer(builder: (context) {
      return SliderWidget(
        key: viewModel.sliderKey,
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
  State<SliderWidget> createState() => SliderWidgetState();
}

class SliderWidgetState extends State<SliderWidget>
    with SingleTickerProviderStateMixin {

  late final AnimationController _controller = AnimationController(
    duration: const Duration(milliseconds: 600),
    vsync: this,
  );

  void animateForward() {
    _controller.forward();
  }
  
  void animateBackward() {
    _controller.reverse();
  }

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
