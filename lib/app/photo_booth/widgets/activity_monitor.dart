import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:loggy/loggy.dart';
import 'package:momento_booth/extensions/go_router_extension.dart';
import 'package:momento_booth/managers/_all.dart';
import 'package:momento_booth/views/start_screen/start_screen.dart';

class ActivityMonitor extends StatefulWidget {

  final GoRouter router;
  final Widget child;

  const ActivityMonitor({super.key, required this.router, required this.child});

  @override
  State<ActivityMonitor> createState() => _ActivityMonitorState();

}

class _ActivityMonitorState extends State<ActivityMonitor> with UiLoggy {

  static const returnHomeTimeout = Duration(seconds: 45);
  late Timer _returnHomeTimer;

  @override
  void initState() {
    super.initState();

    _returnHomeTimer = Timer(returnHomeTimeout, _goHome);
    widget.router.routerDelegate.addListener(_resetTimer);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _onActivity(isTap: true),
      child: widget.child,
    );
  }

  void _onActivity({bool isTap = false}) {
    if (isTap) {
      StatsManager.instance.addTap();
      SfxManager.instance.playClickSound();
    }
    _resetTimer();
  }

  void _resetTimer() {
    _returnHomeTimer.cancel();
    _returnHomeTimer = Timer(returnHomeTimeout, _goHome);
  }

  void _goHome() {
    if (widget.router.currentLocation == StartScreen.defaultRoute) return;
    loggy.debug("No activity in $returnHomeTimeout, returning to homescreen");
    widget.router.go(StartScreen.defaultRoute);
  }

  @override
  void dispose() {
    _returnHomeTimer.cancel();
    widget.router.routerDelegate.removeListener(_resetTimer);
    super.dispose();
  }

}
