import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:momento_booth/managers/settings_manager.dart';
import 'package:newton_particles/newton_particles.dart';

class TouchEffect extends StatefulWidget {
  final Widget child;

  const TouchEffect({super.key, required this.child});

  @override
  State<TouchEffect> createState() => _TouchEffectState();
}

class _TouchEffectState extends State<TouchEffect> {
  Offset? _tapDetails;
  bool get _allowScrollGestureWithMouse => SettingsManager.instance.settings.ui.allowScrollGestureWithMouse;

  @override
  Widget build(BuildContext context) {
    return Observer(builder: (_) {
      //if (!_allowScrollGestureWithMouse) return widget.child;

      return Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (details) => setState(() => _tapDetails = details.position),
        onPointerUp: (details) => _tapDetails = details.position,
        child: Newton(
          activeEffects: [
            if (_tapDetails != null)
              PulseEffect(
                effectConfiguration: EffectConfiguration(
                  emitDuration: 0,
                  particleCount: 50,
                  particlesPerEmit: 25,
                  foreground: true,
                  origin: _tapDetails!,
                  minDistance: 30,
                  maxDistance: 30,
                  minDuration: 250,
                  maxDuration: 250,
                  distanceCurve: Curves.easeInOutBack,
                ),
                particleConfiguration: ParticleConfiguration(
                  shape: CircleShape(),
                  size: const Size(2, 2),
                ),
              ),
          ],
          child: widget.child,
        ),
      );
    });
  }
}
