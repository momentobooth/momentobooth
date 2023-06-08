import 'package:flutter/widgets.dart';
import 'package:momento_booth/views/base/screen_view_base.dart';
import 'package:momento_booth/views/initialization_screen/initialization_screen_controller.dart';
import 'package:momento_booth/views/initialization_screen/initialization_screen_view_model.dart';
import 'package:wave/config.dart';
import 'package:wave/wave.dart';

class InitializationScreenView extends ScreenViewBase<InitializationScreenViewModel, InitializationScreenController> {
  const InitializationScreenView({
    required super.viewModel,
    required super.controller,
    required super.contextAccessor,
  });

  @override
  Widget get body {
    return Column(
      children: [
        const Expanded(
          flex: 1,
          child: SizedBox(),
        ),
        Expanded(
          flex: 1,
          child: _waves,
        ),
      ],
    );
  }

  Widget get _waves {
    return WaveWidget(
      config: CustomConfig(
        colors: const [
          Color(0xFFFEE440),
          Color(0xFF00BBF9),
        ],
        durations: const [
          5000,
          4000,
        ],
        heightPercentages: const [
          0.65,
          0.66,
        ],
      ),
      size: const Size(double.infinity, double.infinity),
      waveAmplitude: 0,
    );
  }
}
