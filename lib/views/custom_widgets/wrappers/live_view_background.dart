import 'dart:ui' as ui;

import 'package:auto_size_text/auto_size_text.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:momento_booth/managers/_all.dart';
import 'package:momento_booth/views/base/stateless_widget_base.dart';

class LiveViewBackground extends StatelessWidgetBase {

  final Widget child;

  const LiveViewBackground({
    super.key,
    required this.child,
  });

  bool get _showLiveViewBackground => PhotosManager.instance.showLiveViewBackground;
  LiveViewState get _liveViewState => LiveViewManager.instance.liveViewState;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      fit: StackFit.expand,
      children: [
        _viewState,
        child,
        _statusOverlay,
      ],
    );
  }

  Widget get _statusOverlay {
    return Padding(
      padding: const EdgeInsets.all(30),
      child: Observer(
        builder: (context) => Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (InfoBar notification in NotificationsManager.instance.notifications) ...[
              notification,
              const SizedBox(height: 8),
            ]
          ],
        ),
      ),
    );
  }

  Widget get _viewState {
    return Observer(builder: (context) {
      switch (_liveViewState) {
        case LiveViewState.initializing:
          return _initializingState;
        case LiveViewState.error:
          return _errorState(Colors.red, null);
        case LiveViewState.streaming:
          return _streamingState;
      }
    });
  }

  Widget get _initializingState {
    return const Center(
      child: ProgressRing(),
    );
  }

  Widget _errorState(Color color, String? message) {
    return ColoredBox(
      color: color,
      child: Center(
        child: AutoSizeText(
          message ?? "Camera could not be found\r\n\r\nor\r\n\r\nconnection broken!",
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget get _streamingState {
    if (LiveViewManager.instance.lastFrameWasInvalid) {
      return _errorState(Colors.green, "Could not decode webcam data");
    }

    return Stack(
      clipBehavior: Clip.none,
      fit: StackFit.expand,
      children: [
        ColoredBox(color: Colors.green),
        LiveView(
          fit: BoxFit.cover,
          textureId: LiveViewManager.instance.textureIdBlur,
        ),
        AnimatedOpacity(
          duration: const Duration(milliseconds: 300),
          opacity: _showLiveViewBackground ? 1 : 0,
          curve: Curves.ease,
          child: LiveView(
            fit: BoxFit.contain,
            textureId: LiveViewManager.instance.textureIdMain,
          ),
        ),
      ],
    );
  }

}

class LiveView extends StatelessWidgetBase {

  final BoxFit fit;
  final int? textureId;

  const LiveView({
    super.key,
    required this.fit,
    this.textureId,
  });

  ui.FilterQuality get _filterQuality => SettingsManager.instance.settings.ui.liveViewFilterQuality.toUiFilterQuality();
  double get _aspectRatio => SettingsManager.instance.settings.hardware.liveViewAndCaptureAspectRatio;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: fit,
      child: Observer(
        builder: (_) {
          return SizedBox(
              width: _aspectRatio,
              height: 1,
              child: textureId != null
                  ? Texture(
                    textureId: textureId!,
                    filterQuality: _filterQuality,
                  )
                  : null,
            );
        }
      ),
    );
  }

}
