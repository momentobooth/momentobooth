import 'package:auto_size_text/auto_size_text.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:go_router/go_router.dart';
import 'package:momento_booth/extensions/go_router_extension.dart';
import 'package:momento_booth/main.dart';
import 'package:momento_booth/managers/_all.dart';
import 'package:momento_booth/models/settings.dart';
import 'package:momento_booth/models/subsystem_status.dart';
import 'package:momento_booth/views/components/imaging/live_view.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/gallery_screen/gallery_screen.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/photo_details_screen/photo_details_screen.dart';

class LiveViewBackground extends StatefulWidget {

  final Widget child;

  const LiveViewBackground({
    super.key,
    required this.child,
  });

  @override
  State<LiveViewBackground> createState() => _LiveViewBackgroundState();

}

class _LiveViewBackgroundState extends State<LiveViewBackground> {

  bool get _showLiveViewBackground => getIt<PhotosManager>().showLiveViewBackground && (GoRouter.of(context).currentLocation != GalleryScreen.defaultRoute && !GoRouter.of(context).currentLocation.startsWith('${PhotoDetailsScreen.defaultRoute}/'));

  BackgroundBlur get _backgroundBlur => getIt<SettingsManager>().settings.ui.backgroundBlur;

  SubsystemStatus get _liveViewState => getIt<LiveViewManager>().subsystemStatus;

  @override
  void initState() {
    super.initState();
    GoRouter.of(context).routerDelegate.addListener(_routerListener);
  }

  void _routerListener() => WidgetsBinding.instance.addPostFrameCallback((_) => setState(() {}));

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
            for (InfoBar notification in getIt<NotificationsManager>().notifications) ...[
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
      return switch (_liveViewState) {
        SubsystemStatusBusy _ => _initializingState,
        SubsystemStatusError error => _errorState(Colors.red, error.message),
        SubsystemStatusOk _ || SubsystemStatusWarning _ => _streamingState,
        _ => throw Exception('Unsupported subsystem status $_liveViewState'),
      };
    });
  }

  Widget get _initializingState {
    return Center(
      child: ProgressRing(activeColor: getIt<ProjectManager>().settings.primaryColor),
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
    if (getIt<LiveViewManager>().lastFrameWasInvalid) {
      return _errorState(Colors.green, "Could not decode webcam data");
    }

    return Stack(
      clipBehavior: Clip.none,
      fit: StackFit.expand,
      children: [
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
    GoRouter.of(context).routerDelegate.removeListener(_routerListener);
    super.dispose();
  }

}
