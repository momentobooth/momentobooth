import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:momento_booth/extensions/build_context_extension.dart';

/// A pill-shaped animated overlay with a frosted glass effect.
class PillContainer extends StatelessWidget {
  /// The text to display inside the pill.
  final String text;
  /// Whether the pill is currently visible.
  final bool visible;

  const PillContainer({
    super.key,
    required this.text,
    required this.visible,
  });

  @override
  Widget build(BuildContext context) {
    const brightness = 1.2;
    const blurSigma = 10.0;
    const borderRadius = 40.0;

    return Align(
      alignment: Alignment.bottomCenter,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        transitionBuilder: (child, animation) {
          return ScaleTransition(
            scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
            child: FadeTransition(opacity: animation, child: child),
          );
        },
        child: visible
            ? ClipRRect(
              borderRadius: BorderRadius.circular(borderRadius),
              child: BackdropFilter(
                filter: ImageFilter.compose(
                  outer: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
                  inner: ColorFilter.matrix([
                    // Increases brightness slightly to mimic the vibrancy effect
                    brightness, 0, 0, 0, 10,
                    0, brightness, 0, 0, 10,
                    0, 0, brightness, 0, 10,
                    0, 0, 0, 1, 0,
                  ]),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(borderRadius),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Text(
                    text,
                    style: context.theme.subtitleTheme.style.copyWith(color: Colors.black, fontSize: 40, height: 1, shadows: []),
                  ),
                ),
              ),
            )
            : const SizedBox.shrink(),
      ),
    );
  }
}
