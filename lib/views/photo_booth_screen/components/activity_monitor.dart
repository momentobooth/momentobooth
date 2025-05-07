import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobx/mobx.dart' hide Listener;
import 'package:momento_booth/extensions/go_router_extension.dart';
import 'package:momento_booth/main.dart';
import 'package:momento_booth/managers/_all.dart';
import 'package:momento_booth/utils/logger.dart';
import 'package:momento_booth/views/photo_booth_screen/notifications/activity_timeout_callback.dart';
import 'package:momento_booth/views/photo_booth_screen/notifications/activity_timeout_callback_cancellation.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/manual_collage_screen/manual_collage_screen.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/start_screen/start_screen.dart';
import 'package:momento_booth/views/settings_screen/settings_screen.dart';

class ActivityMonitor extends StatefulWidget {

  final Widget child;

  const ActivityMonitor({super.key, required this.child});

  @override
  State<ActivityMonitor> createState() => _ActivityMonitorState();

}

class _ActivityMonitorState extends State<ActivityMonitor> with Logger {

  Timer? _returnHomeTimer;
  late ReactionDisposer _resetTimerReactionDisposer;

  /// Registered callbacks that need to be called when the activity timeout occurs.
  final List<FutureOr<void> Function()> _onActivityTimeouts = [];

  @override
  void initState() {
    super.initState();

    GoRouter.of(context).routerDelegate.addListener(_resetTimer);
    _resetTimerReactionDisposer = autorun((_) => _resetTimer());
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
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
    );
  }

  void _onActivity({required bool isTap}) {
    if (isTap) {
      getIt<StatsManager>().addTap();
      getIt<SfxManager>().playClickSound();
    }
    _resetTimer();
  }

  void _resetTimer() {
    _returnHomeTimer?.cancel();
    int timeoutSeconds = getIt<SettingsManager>().settings.ui.returnToHomeTimeoutSeconds;
    if (timeoutSeconds > 0) {
      _returnHomeTimer = Timer(Duration(seconds: timeoutSeconds), _goHome);
    }
  }

  Future<void> _goHome() async {
    String currentLocation = GoRouter.of(context).currentLocation;
    if (currentLocation == StartScreen.defaultRoute ||
        currentLocation == SettingsScreen.defaultRoute ||
        currentLocation == ManualCollageScreen.defaultRoute) {
      return;
    }

    logDebug("Return to Home screen due to activity timeout initiating.");
    for (final onActivityTimeout in _onActivityTimeouts.toList()) {
      logDebug("Running activity timeout callback.");
      await onActivityTimeout();
      _onActivityTimeouts.remove(onActivityTimeout);
    }
    if (!mounted) return;
    GoRouter.of(context).go(StartScreen.defaultRoute);
    logDebug("Return to Home screen due to activity timeout.");
  }

  @override
  void dispose() {
    _returnHomeTimer?.cancel();
    GoRouter.of(context).routerDelegate.removeListener(_resetTimer);
    _resetTimerReactionDisposer();
    super.dispose();
  }

}
