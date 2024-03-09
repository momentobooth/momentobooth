import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter/material.dart';

class PhotoBoothDialog extends StatelessWidget {

  final String? title;
  final Widget? indicator;
  final Widget body;
  final List<Widget> actions;

  const PhotoBoothDialog({
    super.key,
    required this.body,
    this.title,
    this.indicator,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
        decoration: ShapeDecoration(
          color: const Color(0xFFFFFFFF).withOpacity(0.90),
          shape: SmoothRectangleBorder(
            borderRadius: SmoothBorderRadius(
              cornerRadius: 42,
              cornerSmoothing: 1,
            ),
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
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title ?? '',
                        style: const TextStyle(fontSize: 24),
                        textAlign: TextAlign.left,
                      ),
                    ),
                    if (indicator != null)
                      Padding(
                        padding: const EdgeInsets.only(left: 16),
                        child: indicator,
                      ),
                  ],
                ),
              if (title != null || indicator != null)
                Divider(color: Colors.black.withOpacity(0.5)),
              body,
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
      ),
    );
  }

}
