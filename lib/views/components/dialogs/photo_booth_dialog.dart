import 'package:flutter/material.dart';
import 'package:momento_booth/extensions/build_context_extension.dart';
import 'package:momento_booth/models/app_action.dart';
import 'package:momento_booth/views/components/buttons/stateless_photo_booth_button.dart';

class PhotoBoothDialog extends StatelessWidget {

  final double? width;
  final double? height;
  final String? title;
  final Widget? indicator;
  final Widget body;
  final EdgeInsets bodyPadding;
  final List<Widget> actions;
  final List<AppAction>? appActionsOverride;

  List<AppAction> get appActions {
    if (appActionsOverride != null) return appActionsOverride!;
    var buttons = actions.whereType<StatelessPhotoBoothButton>();
    return buttons.map((button) => AppAction(name: button.title.toLowerCase().replaceAll(" ", "_"), callback: (_) { button.onPressed?.call(); })).toList();
  }

  const PhotoBoothDialog({
    super.key,
    this.width,
    this.height,
    required this.body,
    this.title,
    this.indicator,
    this.bodyPadding = const EdgeInsets.symmetric(horizontal: 4.0, vertical: 16.0),
    this.actions = const [],
    this.appActionsOverride,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: const EdgeInsets.all(32.0),
      padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
      decoration: ShapeDecoration(
        color: const Color(0xFFFFFFFF).withValues(alpha: 0.9),
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
                      style: context.theme.dialogTheme.titleStyle,
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
              Divider(color: Colors.black.withValues(alpha: 0.5)),
            Flexible(
              child: Padding(
                padding: bodyPadding,
                child: body,
              ),
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
