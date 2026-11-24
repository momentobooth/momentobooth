import 'package:fluent_ui/fluent_ui.dart';
import 'package:momento_booth/extensions/build_context_extension.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

class PhotoBoothFilledButton extends StatefulWidget {

  final String title;
  final IconData? icon;
  final VoidCallback? onPressed;

  /// When set, the button presses itself after this duration, so a dialog closes when guests walk away. Its background
  /// fills up from start to end in the meantime. Tapping still presses the button right away.
  final Duration? autoPressAfter;

  const PhotoBoothFilledButton({
    super.key,
    required this.title,
    this.icon,
    this.onPressed,
    this.autoPressAfter,
  });

  @override
  State<PhotoBoothFilledButton> createState() => _PhotoBoothFilledButtonState();

}

class _PhotoBoothFilledButtonState extends State<PhotoBoothFilledButton> with TickerProviderStateMixin {

  static final Color _fillColor = Colors.white.withValues(alpha: 0.3);

  AnimationController? _autoPressController;

  @override
  void initState() {
    super.initState();
    _startAutoPress();
  }

  @override
  void didUpdateWidget(PhotoBoothFilledButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.autoPressAfter != oldWidget.autoPressAfter || (widget.onPressed == null) != (oldWidget.onPressed == null)) {
      _autoPressController?.dispose();
      _autoPressController = null;
      _startAutoPress();
    }
  }

  void _startAutoPress() {
    Duration? duration = widget.autoPressAfter;
    // A disabled button cannot be pressed, so it does not count down either.
    if (duration == null || widget.onPressed == null) return;

    _autoPressController = AnimationController(vsync: this, duration: duration)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) widget.onPressed?.call();
      })
      ..forward();
  }

  void _onPressed() {
    // Stop the countdown, so the button is not pressed a second time when it completes.
    _autoPressController?.stop();
    widget.onPressed?.call();
  }

  @override
  void dispose() {
    _autoPressController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ButtonStyle style = context.theme.dialogTheme.buttonStyle;
    Widget button = FilledButton(
      onPressed: widget.onPressed == null ? null : _onPressed,
      style: style,
      child: Row(
        children: [
          if (widget.icon != null)
            Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: Icon(widget.icon, size: 24.0),
            ),
          Text(widget.title),
        ],
      ),
    );

    AnimationController? controller = _autoPressController;
    if (controller != null) {
      ShapeBorder shape = style.shape?.resolve(const {}) ?? RoundedRectangleBorder(borderRadius: BorderRadius.circular(4));
      button = Stack(
        children: [
          button,
          // The fill lies on top of the button, so it does not change the button's own hover and press colors. The
          // label is white, so it stays readable under the white fill.
          Positioned.fill(
            child: IgnorePointer(
              child: ClipPath(
                clipper: ShapeBorderClipper(shape: shape, textDirection: Directionality.maybeOf(context)),
                child: AnimatedBuilder(
                  animation: controller,
                  builder: (context, _) => FractionallySizedBox(
                    alignment: AlignmentDirectional.centerStart,
                    widthFactor: controller.value,
                    child: ColoredBox(color: _fillColor),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: button,
    );
  }

}

@UseCase(name: 'Filled button', type: PhotoBoothFilledButton)
Widget photoBoothFilledButton(BuildContext context) {
  return Center(
    child: PhotoBoothFilledButton(
      title: context.knobs.string(label: 'Title', initialValue: 'Continue'),
      onPressed: () {},
    ),
  );
}

@UseCase(name: 'Filled button with auto press', type: PhotoBoothFilledButton)
Widget photoBoothFilledButtonAutoPress(BuildContext context) {
  int seconds = context.knobs.int.slider(label: 'Auto press after (seconds)', initialValue: 10, min: 1, max: 30);
  return Center(
    child: PhotoBoothFilledButton(
      title: context.knobs.string(label: 'Title', initialValue: 'Continue'),
      onPressed: () {},
      autoPressAfter: Duration(seconds: seconds),
    ),
  );
}
