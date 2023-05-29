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

  static const _colors = [
    Color(0xFFFEE440),
    Color(0xFF00BBF9),
  ];

  static const _durations = [
    5000,
    4000,
  ];

  static const _heightPercentages = [
    0.65,
    0.66,
  ];

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
          child: WaveWidget(
            config: CustomConfig(
              colors: _colors,
              durations: _durations,
              heightPercentages: _heightPercentages,
            ),
            size: const Size(double.infinity, double.infinity),
            waveAmplitude: 0,
          ),
        ),
      ],
    );
  }
}
