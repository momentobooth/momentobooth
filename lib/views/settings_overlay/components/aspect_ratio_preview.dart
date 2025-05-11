import 'package:fluent_ui/fluent_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class AspectRatioPreview extends StatelessWidget {

  final double aspectRatio;

  const AspectRatioPreview({super.key, required this.aspectRatio});

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 32,
      child: Align(
        child: AspectRatio(
          aspectRatio: aspectRatio,
          child: DecoratedBox(
            decoration: BoxDecoration(border: Border.all()),
            child: FittedBox(child: Padding(padding: EdgeInsets.all(2), child: Icon(LucideIcons.users))),
          ),
        ),
      ),
    );
  }

}
