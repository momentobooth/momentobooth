import 'package:flutter/material.dart';

class PhotoBoothDialog extends StatelessWidget {

  final double? width;
  final double? height;
  final String? title;
  final Widget? indicator;
  final Widget body;
  final EdgeInsets bodyPadding;
  final List<Widget> actions;

  const PhotoBoothDialog({
    super.key,
    this.width,
    this.height,
    required this.body,
    this.title,
    this.indicator,
    this.bodyPadding = const EdgeInsets.symmetric(horizontal: 4.0, vertical: 16.0),
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: const EdgeInsets.all(32.0),
      padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
      decoration: ShapeDecoration(
        color: const Color(0xFFFFFFFF).withOpacity(0.90),
        shape: ContinuousRectangleBorder(
          borderRadius: BorderRadius.circular(96),
        ),
        shadows: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: IntrinsicWidth(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (title != null || indicator != null)
              Padding(
                padding: const EdgeInsets.all(4.0),
                child: Row(
                  children: [
                    Text(
                      title ?? '',
                      style: const TextStyle(fontSize: 24),
                      textAlign: TextAlign.left,
                      strutStyle: const StrutStyle(
                        forceStrutHeight: true,
                        height: 1.75,
                      )
                    ),
                    if (indicator != null)
                      Padding(
                        padding: const EdgeInsets.only(left: 12.0),
                        child: indicator,
                      ),
                  ],
                ),
              ),
            if (title != null || indicator != null)
              Divider(color: Colors.black.withOpacity(0.5)),
            Padding(
              padding: bodyPadding,
              child: body,
            ),
            if (actions.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: actions.map((action) => Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: action,
                  )).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

}
