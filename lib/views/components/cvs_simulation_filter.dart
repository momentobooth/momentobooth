import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:momento_booth/main.dart';
import 'package:momento_booth/managers/settings_manager.dart';
import 'package:momento_booth/utils/color_vision_deficiency.dart';

class CvsSimulationFilter extends StatelessWidget {
  final Widget child;

  const CvsSimulationFilter({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Observer(builder: (contect) {
      if (getIt<SettingsManager>().settings.debug.simulateCvd == ColorVisionDeficiency.none) return child;

      return ColorFiltered(
        colorFilter: const ColorFilter.linearToSrgbGamma(),
        child: ColorFiltered(
          colorFilter: ColorFilter.matrix(
            getIt<SettingsManager>().settings.debug.simulateCvd.colorMatrices[
              getIt<SettingsManager>().settings.debug.simulateCvdSeverity
            ],
          ),
          child: ColorFiltered(colorFilter: const ColorFilter.srgbToLinearGamma(), child: child),
        ),
      );
    });
  }
}
