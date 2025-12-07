import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// A widget that periodically displays a Lottie animation at a random position
/// on the screen with fade-in and fade-out effects.
class RepeatingIndicator extends StatefulWidget {
  /// The path to the Lottie asset file.
  final String lottieAsset;

  /// The duration of the complete show/hide cycle (e.g., 10 seconds).
  final Duration cycleDuration;

  /// The visible duration of the animation (play time + fade-out time).
  final Duration animationDuration;

  /// The size (width and height) of the Lottie widget.
  final double size;

  /// The margin from the screen edges where the animation can appear.
  final double margin;

  const RepeatingIndicator({
    super.key,
    required this.lottieAsset,
    this.cycleDuration = const Duration(seconds: 10),
    this.animationDuration = const Duration(milliseconds: 1500),
    this.size = 200.0,
    this.margin = 100.0,
  });

  @override
  State<RepeatingIndicator> createState() => _RepeatingIndicatorState();
}

class _RepeatingIndicatorState extends State<RepeatingIndicator> with TickerProviderStateMixin {
  static const _fadeDuration = 300; // milliseconds

  // State variables
  Timer? _timer;
  bool _isVisible = false;
  double _currentLeft = 0;
  double _currentTop = 0;
  LottieComposition? _composition;
  late final AnimationController _lottieController;

  @override
  void initState() {
    super.initState();
    // Initialize the Lottie controller
    _lottieController = AnimationController(vsync: this);
    // Start the repeating timer
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _lottieController.dispose();
    super.dispose();
  }

  /// Calculates a random position within the widget's bounds,
  /// respecting the defined margin.
  void _calculateRandomPosition(Size parentSize) {
    final random = Random();
    final maxWidth = parentSize.width - (2 * widget.margin) - widget.size;
    final maxHeight = parentSize.height - (2 * widget.margin) - widget.size;

    setState(() {
      _currentLeft = widget.margin + random.nextDouble() * maxWidth;
      _currentTop = widget.margin + random.nextDouble() * maxHeight;
    });
  }

  /// Manages the full cycle: show, play, hide.
  void _showLottieEffect(Size parentSize) {
    // 1. Calculate new random position
    _calculateRandomPosition(parentSize);
    
    // 2. Start the fade-in and make the widget visible.
    setState(() {
      _isVisible = true;
    });

    // 3. Start Lottie animation playback after a short delay for the fade-in.
    // The fade-in will be handled by the TweenAnimationBuilder below.
    Future.delayed(const Duration(milliseconds: _fadeDuration), () {
      if (mounted) {
        _lottieController.forward(from: 0.0);
      }
    });

    // 4. Hide the widget after the animation duration (including fade-out time).
    Future.delayed(widget.animationDuration, () {
      if (mounted) {
        setState(() {
          _isVisible = false;
        });
        // Reset Lottie controller after it has finished
        _lottieController.reset();
      }
    });
  }

  /// Starts a periodic timer that triggers the Lottie effect.
  void _startTimer() {
    _timer = Timer.periodic(widget.cycleDuration, (timer) {
      // We need the size of the parent widget, which is only available inside
      // the build method or after it. We use `WidgetsBinding.instance.addPostFrameCallback`
      // to get the size in a safe way if the context is available.
      if (mounted && context.findRenderObject() != null) {
        final renderBox = context.findRenderObject()! as RenderBox;
        final parentSize = renderBox.size;
        _showLottieEffect(parentSize);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // The main content of the screen must wrap this widget. 
    // This widget should be placed at the top of the content's Stack.
    return Stack(
      children: [
        // Use a LayoutBuilder if you need the parent size immediately, 
        // but for a periodic timer, the current approach in _startTimer is safer.
        
        // TweenAnimationBuilder for the fade-in and fade-out effect.
        TweenAnimationBuilder<double>(
          // '1.0' when visible, '0.0' when hidden.
          tween: Tween<double>(begin: _isVisible ? 0.0 : 1.0, end: _isVisible ? 1.0 : 0.0),
          duration: const Duration(milliseconds: _fadeDuration), // Fade duration
          builder: (context, opacity, child) {
            return Positioned(
              left: _currentLeft,
              top: _currentTop,
              child: Opacity(
                opacity: opacity,
                child: child,
              ),
            );
          },
          // The Lottie widget is the child that gets positioned and faded.
          child: Lottie.asset(
            widget.lottieAsset,
            width: widget.size,
            height: widget.size,
            fit: BoxFit.contain,
            frameRate: FrameRate.max,
            controller: _lottieController,
            delegates: LottieDelegates(
              values: [
                ValueDelegate.colorFilter(
                  const ['**'],
                  value: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                ),
              ]
            ),
            onLoaded: (composition) {
              // Ensure the animation only plays for the specified duration
              if (_composition == null) {
                _composition = composition;
                // Set the duration of the Lottie controller to match the required animation duration
                _lottieController.duration = widget.animationDuration; 
              }
            },
          ),
        ),
      ],
    );
  }
}
