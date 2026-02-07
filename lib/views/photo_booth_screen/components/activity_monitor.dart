import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobx/mobx.dart' hide Listener;
import 'package:momento_booth/extensions/build_context_extension.dart';
import 'package:momento_booth/extensions/go_router_extension.dart';
import 'package:momento_booth/main.dart';
import 'package:momento_booth/managers/_all.dart';
import 'package:momento_booth/utils/logger.dart';
import 'package:momento_booth/views/components/indicators/capture_counter.dart';
import 'package:momento_booth/views/photo_booth_screen/notifications/activity_timeout_callback.dart';
import 'package:momento_booth/views/photo_booth_screen/notifications/activity_timeout_callback_cancellation.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/manual_collage_screen/manual_collage_screen.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/start_screen/start_screen.dart';
import 'package:provider/provider.dart';

class ActivityMonitor extends StatefulWidget {

  final Widget child;

  const ActivityMonitor({super.key, required this.child});

  @override
  State<ActivityMonitor> createState() => _ActivityMonitorState();

}

class _ActivityMonitorState extends State<ActivityMonitor> with Logger {

  late GoRouterDelegate _routerDelegate;
  late ActivityMonitorController _activityMonitorController;

  Timer? _showReturnHomeWarningTimer;
  late ReactionDisposer _resetTimerReactionDisposer;

  // State to control the warning overlay
  bool _showTimeoutWarning = false;
  static const int _defaultWarningDuration = 10;
  int _currentWarningDuration = _defaultWarningDuration;

  /// Registered callbacks that need to be called when the activity timeout occurs.
  final List<FutureOr<void> Function()> _onActivityTimeouts = [];

  @override
  void initState() {
    super.initState();
    _routerDelegate = GoRouter.of(context).routerDelegate..addListener(_resetTimer);
    _resetTimerReactionDisposer = autorun((_) => _resetTimer());
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Focus(
          onKeyEvent: (node, event) {
            _onActivity(isTap: false);
            return KeyEventResult.ignored;
          },
          child: Listener(
            behavior: HitTestBehavior.translucent,
            onPointerDown: (_) => _onActivity(isTap: true), // Handle mouse clicks and touchscreen taps.
            onPointerSignal: (_) => _onActivity(isTap: false), // Handle scrolling.
            child: NotificationListener<ActivityTimeoutCallback>(
              onNotification: (notificaton) {
                _onActivityTimeouts.add(notificaton.onActivityTimeout);
                return true;
              },
              child: NotificationListener<ActivityTimeoutCallbackCancellation>(
                onNotification: (notificaton) {
                  _onActivityTimeouts.remove(notificaton.onActivityTimeout);
                  return true;
                },
                child: widget.child,
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            child: _showTimeoutWarning
                ? GestureDetector(
                    key: const ValueKey('WarningOverlay'),
                    // Absorb taps to prevent interaction with underlying app, but register activity to reset timer
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _onActivity(isTap: true),
                    child: Container(
                      width: double.infinity,
                      height: double.infinity,
                      color: Colors.black.withValues(alpha: 0.6),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              context.localizations.inactivityWarning,
                              textAlign: TextAlign.center,
                              style: context.theme.subtitleTheme.style,
                            ),
                            const SizedBox(height: 30),
                            SizedBox(
                              width: 350,
                              height: 350,
                              child: CaptureCounter(
                                counterStart: _currentWarningDuration,
                                onCounterFinished: _goHome,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }

  void _onActivity({required bool isTap}) {
    if (isTap) {
      getIt<StatsManager>().addTap();
      getIt<SfxManager>().playClickSound();
    }
    _resetTimer();
  }

  bool get _activityTimeoutDisabled {
    String currentLocation = GoRouter.of(context).currentLocation;
    return currentLocation == StartScreen.defaultRoute ||
        currentLocation == ManualCollageScreen.defaultRoute ||
        context.read<ActivityMonitorController>().isPaused;
  }

  void _resetTimer() {
    _showReturnHomeWarningTimer?.cancel();

    // Hide warning if it was active
    if (_showTimeoutWarning && mounted) {
      setState(() {
        _showTimeoutWarning = false;
      });
    }

    if (_activityTimeoutDisabled) { return; }

    int timeoutSeconds = getIt<SettingsManager>().settings.ui.returnToHomeTimeoutSeconds;

    if (timeoutSeconds > 0) {
      // Logic: If timeout is long, wait until (Total - Warning) to show overlay.
      // If timeout is short (<= Warning), show overlay immediately (after 0 delay).
      int safeTime = 0;

      if (timeoutSeconds > _defaultWarningDuration) {
        safeTime = timeoutSeconds - _defaultWarningDuration;
        _currentWarningDuration = _defaultWarningDuration;
      } else {
        safeTime = 0;
        _currentWarningDuration = timeoutSeconds;
      }

      // When the timer finishes, it will show the warning overlay. The CaptureCounter inside the overlay will trigger _goHome when it finishes.
      // The !_activityTimeoutDisabled guard inside the timer callback ensures the warning won't show if the activity monitor should be paused, such as when the settings overlay is open.
      _showReturnHomeWarningTimer = Timer(Duration(seconds: safeTime), () {
        if (mounted && !_activityTimeoutDisabled) {
          setState(() {
            _showTimeoutWarning = true;
          });
        }
      });
    }
  }

  /// Get's called by the CaptureCountdown widget when the activity timeout occurs.
  /// Executes all registered activity timeout callbacks and navigates back to the home screen.
  Future<void> _goHome() async {
    // The CaptureCounter has no way to cancel the timer and activity may have resumed in the meantime.
    // Therefore, we check again if the activity monitor is disabled or the warning should not be shown anymore.
    if (_activityTimeoutDisabled || !_showTimeoutWarning) { return; }

    logDebug("Return to Home screen due to activity timeout initiating.");
    for (final onActivityTimeout in _onActivityTimeouts.toList()) {
      logDebug("Running activity timeout callback.");
      await onActivityTimeout();
      _onActivityTimeouts.remove(onActivityTimeout);
    }
    if (!mounted) return;

    // Ensure warning is hidden before navigating
    setState(() => _showTimeoutWarning = false);

    GoRouter.of(context).go(StartScreen.defaultRoute);
    logDebug("Return to Home screen due to activity timeout.");
  }

  @override
  void didChangeDependencies() {
    _activityMonitorController = context.read<ActivityMonitorController>()..addListener(_onControllerStateChanged);
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    _showReturnHomeWarningTimer?.cancel();
    _routerDelegate.removeListener(_resetTimer);
    _activityMonitorController.removeListener(_onControllerStateChanged);
    _resetTimerReactionDisposer();
    super.dispose();
  }

  void _onControllerStateChanged() {
    if (!context.read<ActivityMonitorController>().isPaused) _resetTimer();
  }

}

class ActivityMonitorController extends ChangeNotifier {

  bool _isPaused = false;

  bool get isPaused => _isPaused;

  void pause() {
    _isPaused = true;
    notifyListeners();
  }

  void resume() {
    _isPaused = false;
    notifyListeners();
  }

}
