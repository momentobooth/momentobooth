import 'package:auto_size_text/auto_size_text.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:go_router/go_router.dart';
import 'package:momento_booth/extensions/go_router_extension.dart';
import 'package:momento_booth/managers/_all.dart';
import 'package:momento_booth/models/settings.dart';
import 'package:momento_booth/views/custom_widgets/wrappers/live_view.dart';
import 'package:momento_booth/views/gallery_screen/gallery_screen.dart';

class LiveViewBackground extends StatefulWidget {

  final GoRouter router;
  final Widget child;

  const LiveViewBackground({
    super.key,
    required this.router,
    required this.child,
  });

  @override
  State<LiveViewBackground> createState() => _LiveViewBackgroundState();

}

class _LiveViewBackgroundState extends State<LiveViewBackground> {

  bool get _showLiveViewBackground => PhotosManager.instance.showLiveViewBackground && widget.router.currentLocation != GalleryScreen.defaultRoute;

  BackgroundBlur get _backgroundBlur => SettingsManager.instance.settings.ui.backgroundBlur;

  LiveViewState get _liveViewState => LiveViewManager.instance.liveViewState;

  @override
  void initState() {
    super.initState();
    widget.router.routerDelegate.addListener(_routerListener);
  }

  void _routerListener() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      fit: StackFit.expand,
      children: [
        _viewState,
        widget.child,
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
            ],
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
        if (_backgroundBlur == BackgroundBlur.textureBlur)
          const LiveView(
            fit: BoxFit.cover,
            blur: true,
          ),
        AnimatedOpacity(
          duration: const Duration(milliseconds: 300),
          opacity: _showLiveViewBackground ? 1 : 0,
          curve: Curves.ease,
          child: const LiveView(
            fit: BoxFit.contain,
            blur: false,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    widget.router.routerDelegate.removeListener(_routerListener);
    super.dispose();
  }

}
