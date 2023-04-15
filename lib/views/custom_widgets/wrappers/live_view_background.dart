import 'dart:ui';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_rust_bridge_example/managers/live_view_manager.dart';
import 'package:flutter_rust_bridge_example/views/base/stateless_widget_base.dart';

class LiveViewBackground extends StatelessWidgetBase {

  final Widget child;

  const LiveViewBackground({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        _viewState,
        child,
      ]
    );
  }

  Widget get _viewState {
    return Observer(builder: (context) {
      switch (LiveViewManagerBase.instance.liveViewState) {
        
        case LiveViewState.initializing:
          return _initializingState;
        case LiveViewState.error:
          return _errorState;
        case LiveViewState.streaming:
          return _streamingState;

      }
    });
  }

  Widget get _initializingState {
    return FluentTheme(
      data: FluentThemeData(),
      child: Center(
        child: ProgressRing(),
      ),
    );
  }

  Widget get _errorState {
    return ColoredBox(
      color: Colors.green,
      child: Center(
        child: AutoSizeText(
          "Camera could not be found\r\n\r\nor\r\n\r\nconnection broken!",
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget get _streamingState {
    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: Colors.green),
        ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: RawImage(
            image: LiveViewManagerBase.instance.lastFrameImage,
            fit: BoxFit.cover,
          ),
        ),
        RawImage(
          image: LiveViewManagerBase.instance.lastFrameImage,
          fit: BoxFit.contain,
        ),
      ],
    );
  }

}
