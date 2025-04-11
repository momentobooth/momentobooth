import 'package:flutter/widgets.dart';
import 'package:momento_booth/extensions/build_context_extension.dart';

class RotatingCollageBox extends StatefulWidget {

  final double turns;
  final Widget collage;
  final VoidCallback onRotateCompleted;

  const RotatingCollageBox({super.key, required this.turns, required this.collage, required this.onRotateCompleted});

  @override
  State<RotatingCollageBox> createState() => _RotatingCollageBoxState();

}

class _RotatingCollageBoxState extends State<RotatingCollageBox> with SingleTickerProviderStateMixin {

  late final AnimationController _controller = AnimationController(vsync: this, duration: Duration(milliseconds: 300));
  late Animation<double> _rotation;

  @override
  void initState() {
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) widget.onRotateCompleted();
    });
    _rotation = Tween<double>(begin: 0.0, end: widget.turns).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _controller.forward();
    super.initState();
  }

  @override
  void didUpdateWidget(covariant RotatingCollageBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.turns != widget.turns) {
      _rotation = Tween<double>(
        begin: _rotation.value,
        end: widget.turns,
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOutQuint));
      _controller
        ..reset()
        ..forward();
    } else {
      widget.onRotateCompleted();
    }
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _rotation,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 255, 255, 255),
          boxShadow: [context.theme.chooseCaptureModeButtonShadow],
        ),
        child: widget.collage,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

}
