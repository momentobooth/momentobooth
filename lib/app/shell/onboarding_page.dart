import 'dart:async';
import 'dart:math';

import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' show Icons;
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:mobx/mobx.dart';
import 'package:momento_booth/extensions/build_context_extension.dart';
import 'package:momento_booth/main.dart';
import 'package:momento_booth/managers/_all.dart';
import 'package:momento_booth/models/subsystem_status.dart';
import 'package:momento_booth/utils/subsystem.dart';

class OnboardingPage extends StatefulWidget {

  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();

}

class _OnboardingPageState extends State<OnboardingPage> {

  static const int _gradientCount = 3;

  final _random = Random();
  late List<Gradient> _gradients;

  @override
  void initState() {
    _updateGradients();

    Timer.periodic(
      const Duration(seconds: 10),
      (_) => _updateGradients(),
    );

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) => _updateGradients());

    super.initState();
  }

  void _updateGradients() {
    setState(() {
      _gradients = List.generate(
          _gradientCount,
          (i) => RadialGradient(
                radius: _random.nextDouble() / 3 + 0.30,
                center: Alignment(
                  _random.nextDouble() * (_random.nextBool() ? -1 : 1),
                  _random.nextDouble() * (_random.nextBool() ? -1 : 1),
                ),
                focalRadius: 100,
                colors: [
                  _getRandomLightBlueTint(),
                  const Color.fromARGB(0, 255, 255, 255),
                ],
              ),
          growable: false);
    });
  }

  Color _getRandomLightBlueTint() {
    final possibleColors = [Colors.blue.light, Colors.blue.lightest];
    final chosenColor = possibleColors[_random.nextInt(possibleColors.length)];
    return chosenColor.withOpacity(_random.nextDouble());
  }

  @override
  Widget build(BuildContext context) {
    //final FluentThemeData themeData = FluentTheme.of(context);
    ObservableList list = getIt.get<ObservableList<Subsystem>>();
    print(list);

    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: Colors.white),
        ..._gradients.map((g) => AnimatedContainer(
              duration: const Duration(seconds: 10),
              decoration: BoxDecoration(
                gradient: g,
              ),
            )),
        Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 800,
              minHeight: 500,
            ),
            child: _getCenterWidget(context),
          ),
        ),
        // Align(
        //   alignment: Alignment.bottomCenter,
        //   child: OnboardingVersionInfo(
        //     appVersionInfo: _appVersionInfo,
        //   ),
        // ),
      ],
    );
  }

  Widget _getCenterWidget(BuildContext context) {
    return Acrylic(
      elevation: 16.0,
      luminosityAlpha: 0.9,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Initializing app",
              style: FluentTheme.of(context).typography.title,
            ),
            Observer(
              builder: (context) => Column(
                children: [
                  _subsystemStatusCard("Window manager", getIt<WindowManager>().subsystemStatus, context),
                  _subsystemStatusCard("Settings", getIt<SettingsManager>().subsystemStatus, context),
                  _subsystemStatusCard("Statistics", getIt<StatsManager>().subsystemStatus, context),
                  _subsystemStatusCard("Live view", getIt<LiveViewManager>().subsystemStatus, context),
                  _subsystemStatusCard("MQTT", getIt<MqttManager>().subsystemStatus, context),
                  _subsystemStatusCard("Printing", getIt<PrintingManager>().subsystemStatus, context),
                  _subsystemStatusCard("Sounds", getIt<SfxManager>().subsystemStatus, context),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              // What a nice way of making a bigger button /s
              child: Transform.scale(scale: 1.3, child: Button(onPressed: () { context.router.go('/photo_booth'); }, child: Text("Continue to app"))),
            )
          ],
        ),
      ),
    );
  }

}

Widget _subsystemStatusCard(String name, SubsystemStatus status, BuildContext context) {
  const defaultMessage = "No message";
  final String message = switch(status) {
    SubsystemStatusOk(message: var m) => m ?? defaultMessage,
    SubsystemStatusBusy(message: var m) => m,
    SubsystemStatusWarning(message: var m) => m,
    SubsystemStatusError(message: var m) => m,
    _ => defaultMessage
  };

  final ActionMap actions = switch(status) {
    SubsystemStatusOk(actions: var a) => a,
    // SubsystemStatusDeferred(actions: var a) => a,
    SubsystemStatusDisabled(actions: var a) => a,
    SubsystemStatusBusy(actions: var a) => a,
    SubsystemStatusWarning(actions: var a) => a,
    SubsystemStatusError(actions: var a) => a,
    _ => {}
  };

  final icon = switch(status) {
    SubsystemStatusInitial() => Icons.pending_outlined,
    SubsystemStatusOk() => Icons.check,
    // SubsystemStatusDeferred() => a,
    SubsystemStatusDisabled() => Icons.do_disturb_alt,
    SubsystemStatusBusy() => Icons.hourglass_empty,
    SubsystemStatusWarning() => Icons.warning_amber,
    SubsystemStatusError() => Icons.error,
    _ => Icons.question_mark
  };

  final statusStr = status.toString().substring(16).split('(').first.capitalize;

  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 10.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(name, style: FluentTheme.of(context).typography.subtitle),
        Row(children: [
          SizedBox(
            width: 150,
            // Create row with subsystem status
            child: Row(
              children: [
                Text("Status: ", style: FluentTheme.of(context).typography.body),
                Text(statusStr, style: FluentTheme.of(context).typography.bodyStrong),
                SizedBox(width: 5.0),
                Transform.translate(
                  offset: Offset(0, 1),
                  child: Icon(icon)
                ),
              ],
            )),
          
          // Display action buttons, if available
          if (actions.isEmpty)
            Opacity(opacity: 0.5, child: Text("No actions", style: FluentTheme.of(context).typography.body)),
          if (actions.isNotEmpty)
            Row(children: [
              for (final e in actions.entries)
                Button(onPressed: e.value, child: Text(e.key))
            ],),
        ],),
        // Display detailed status message
        Text(message, style: FluentTheme.of(context).typography.body),
      ],
    ),
  );
}
