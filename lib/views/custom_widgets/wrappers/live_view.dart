import 'dart:ui' as ui;
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:momento_booth/managers/_all.dart';
import 'package:momento_booth/views/base/stateless_widget_base.dart';

class LiveView extends StatelessWidgetBase {

  final BoxFit fit;
  final int? textureId;

  const LiveView({
    super.key,
    required this.fit,
    this.textureId,
  });

  ui.FilterQuality get _filterQuality => SettingsManager.instance.settings.ui.liveViewFilterQuality.toUiFilterQuality();
  double get _aspectRatio => SettingsManager.instance.settings.hardware.liveViewAndCaptureAspectRatio;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: fit,
      child: Observer(
        builder: (_) {
          return SizedBox(
              width: _aspectRatio,
              height: 1,
              child: textureId != null
                  ? Texture(
                    textureId: textureId!,
                    filterQuality: _filterQuality,
                  )
                  : null,
            );
        }
      ),
    );
  }

}
