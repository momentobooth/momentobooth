import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' show Icons;
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:momento_booth/extensions/build_context_extension.dart';
import 'package:momento_booth/main.dart';
import 'package:momento_booth/managers/_all.dart';
import 'package:momento_booth/models/subsystem_status.dart';

class StatusPage extends StatelessWidget {

  const StatusPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 24, 32, 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SvgPicture.asset(
              'assets/svg/undraw_server-status_f685.svg',
            ),
          ),
          const SizedBox(width: 64.0),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Initializing app",
                  style: FluentTheme.of(context).typography.title,
                ),
                Expanded(
                  child: Observer(
                    builder: (context) => ListView(
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
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(
                    onPressed: () { context.router.go('/photo_booth'); }, child: Text("Continue to app"),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _subsystemStatusCard(String name, SubsystemStatus status, BuildContext context) {
    const defaultMessage = "No message";
    final String message = switch (status) {
      SubsystemStatusOk(message: var m) => m ?? defaultMessage,
      SubsystemStatusBusy(message: var m) => m,
      SubsystemStatusWarning(message: var m) => m,
      SubsystemStatusError(message: var m) => m,
      _ => defaultMessage
    };

    final ActionMap actions = switch (status) {
      SubsystemStatusOk(actions: var a) => a,
      // SubsystemStatusDeferred(actions: var a) => a,
      SubsystemStatusDisabled(actions: var a) => a,
      SubsystemStatusBusy(actions: var a) => a,
      SubsystemStatusWarning(actions: var a) => a,
      SubsystemStatusError(actions: var a) => a,
      _ => {}
    };

    final icon = switch (status) {
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
          Row(
            children: [
              SizedBox(
                  width: 150,
                  // Create row with subsystem status
                  child: Row(
                    children: [
                      Text("Status: ", style: FluentTheme.of(context).typography.body),
                      Text(statusStr, style: FluentTheme.of(context).typography.bodyStrong),
                      SizedBox(width: 5.0),
                      Transform.translate(offset: Offset(0, 1), child: Icon(icon)),
                    ],
                  )),

              // Display action buttons, if available
              if (actions.isEmpty)
                Opacity(opacity: 0.5, child: Text("No actions", style: FluentTheme.of(context).typography.body)),
              if (actions.isNotEmpty)
                Row(
                  children: [for (final e in actions.entries) Button(onPressed: e.value, child: Text(e.key))],
                ),
            ],
          ),
          // Display detailed status message
          Text(message, style: FluentTheme.of(context).typography.body),
        ],
      ),
    );
  }

}
