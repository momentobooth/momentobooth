import 'package:flutter/material.dart';

class PulsatingOpacity extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Curve curve;
  final double minOpacity;
  final double maxOpacity;

  const PulsatingOpacity({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 400),
    this.curve = Curves.easeInOut,
    this.minOpacity = 0.2,
    this.maxOpacity = 1.0,
  });

  @override
  State<PulsatingOpacity> createState() => _PulsatingOpacityState();
}

class _PulsatingOpacityState extends State<PulsatingOpacity>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _animation = Tween<double>(begin: widget.minOpacity, end: widget.maxOpacity).animate(
      CurvedAnimation(
        parent: _controller,
        curve: widget.curve,
      ),
    );

    _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant PulsatingOpacity oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If duration or curve changes, re-initialize the controller and animation
    if (widget.duration != oldWidget.duration ||
        widget.curve != oldWidget.curve ||
        widget.minOpacity != oldWidget.minOpacity ||
        widget.maxOpacity != oldWidget.maxOpacity) {
      _controller.duration = widget.duration;
      _animation = Tween<double>(begin: widget.minOpacity, end: widget.maxOpacity).animate(
        CurvedAnimation(
          parent: _controller,
          curve: widget.curve,
        ),
      );
      _controller.repeat(reverse: true); // Restart with new settings
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: widget.child,
        );
      },
    );
  }
}
