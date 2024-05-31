import 'package:fluent_ui/fluent_ui.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:momento_booth/models/subsystem_status.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

class SubsystemStatusIndicator extends StatelessWidget {

  final SubsystemStatus status;

  const SubsystemStatusIndicator({super.key, required this.status});

  Color get _color => switch (status) {
        SubsystemStatusBusy _ => Colors.white,
        SubsystemStatusOk _ => Colors.green,
        SubsystemStatusDisabled _ => Colors.grey,
        SubsystemStatusWarning _ => Colors.orange,
        SubsystemStatusError _ => Colors.red,
        _ => Colors.purple,
      };

  IconData get _icon => switch (status) {
        SubsystemStatusBusy _ => FontAwesomeIcons.spinner,
        SubsystemStatusOk _ => FontAwesomeIcons.check,
        SubsystemStatusDisabled _ => FontAwesomeIcons.slash,
        SubsystemStatusWarning _ => FontAwesomeIcons.exclamation,
        SubsystemStatusError _ => FontAwesomeIcons.xmark,
        _ => FontAwesomeIcons.question,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4.0),
      decoration: BoxDecoration(
        border: Border.all(color: _color),
        shape: BoxShape.circle,
      ),
      child: Icon(_icon, color: _color, size: 12),
    );
  }

}

@widgetbook.UseCase(
  name: 'Subsystem Status Indicator',
  type: SubsystemStatusIndicator,
)
Widget subsystemStatusIndicatorUseCase(BuildContext context) {
  return SubsystemStatusIndicator(
    status: context.knobs.list<SubsystemStatus>(
      label: "Status",
      options: const [
        SubsystemStatus.busy(message: ""),
        SubsystemStatus.ok(message: ""),
        SubsystemStatus.disabled(),
        SubsystemStatus.warning(message: ""),
        SubsystemStatus.error(message: ""),
      ],
      initialOption: const SubsystemStatus.ok(message: ""),
      labelBuilder: (value) =>
          value.runtimeType.toString().replaceFirst('_\$SubsystemStatus', '').replaceFirst('Impl', ''),
    ),
  );
}
