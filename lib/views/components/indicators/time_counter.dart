import 'package:flutter/widgets.dart';

class TimeCounter extends StatefulWidget {
  final TextStyle textStyle;

  const TimeCounter({
    Key? key,
    this.textStyle = const TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 50,
      color: Color.fromARGB(255, 255, 255, 255), // Default color for the text
    ),
  }) : super(key: key);

  @override
  _TimeCounterState createState() => _TimeCounterState();
}

class _TimeCounterState extends State<TimeCounter> with TickerProviderStateMixin {
  late AnimationController _controller;
  DateTime _startTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now(); // Initialize start time
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(days: 365), // A long duration, as we'll just read elapsed time
    )..addListener(() {
        setState(() {
          // Rebuilds the widget on every tick, updating the time
        });
      })
      ..repeat(); // Start repeating to continuously trigger updates
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Duration elapsed = DateTime.now().difference(_startTime);

    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String threeDigits(int n) => n.toString().padLeft(3, '0');

    final minutes = twoDigits(elapsed.inMinutes.remainder(60));
    final seconds = twoDigits(elapsed.inSeconds.remainder(60));
    final milliseconds = threeDigits(elapsed.inMilliseconds.remainder(1000));

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Minutes with animation
        buildAnimatedTimeDigit(minutes[0], ValueKey<String>('min1_${minutes[0]}')),
        buildAnimatedTimeDigit(minutes[1], ValueKey<String>('min2_${minutes[1]}')),
        buildSeparator(),
        // Seconds with animation
        buildAnimatedTimeDigit(seconds[0], ValueKey<String>('sec1_${seconds[0]}')),
        buildAnimatedTimeDigit(seconds[1], ValueKey<String>('sec2_${seconds[1]}')),
        buildSeparator(),
        // Milliseconds without animation
        Text(
          milliseconds,
          style: widget.textStyle,
        ),
      ],
    );
  }

  Widget buildAnimatedTimeDigit(String digit, Key key) {
    const offset = 0.7;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      switchInCurve: Curves.easeOut, // New number entering
      switchOutCurve: Curves.easeIn,  // Old number exiting
      transitionBuilder: (Widget child, Animation<double> animation) {
        // The 'child' argument here is the current widget being animated.
        // During a switchIn, it's the *new* digit.
        // During a switchOut, it's the *old* digit.

        final bool isEntering = child.key == key; // Compare the key to determine if it's the entering widget

        return SlideTransition(
          position: Tween<Offset>(
            begin: isEntering ? const Offset(0, -offset) : const Offset(0, offset), // New comes from above, old goes down (for some reason specified as beginning)
            end: Offset.zero, // Zero is nominal position
          ).animate(animation),
          child: FadeTransition(
            opacity: animation,
            child: child, // The actual Text widget provided by AnimatedSwitcher
          ),
        );
      },
      child: Text(
        digit,
        key: key, // Critical for AnimatedSwitcher to identify changes
        style: widget.textStyle,
      ),
    );
  }

  Widget buildSeparator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2.0),
      child: Text(
        ":",
        style: widget.textStyle,
      ),
    );
  }
}
