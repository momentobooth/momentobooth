import 'package:fluent_ui/fluent_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:momento_booth/models/subsystem_status.dart';
import 'package:momento_booth/views/components/indicators/subsystem_status_icon.dart';

class SubsystemStatusDisplay extends StatefulWidget {

  final String title;
  final SubsystemStatus status;

  const SubsystemStatusDisplay({
    super.key,
    required this.title,
    required this.status,
  });

  @override
  State<SubsystemStatusDisplay> createState() => _SubsystemStatusDisplayState();

}

class _SubsystemStatusDisplayState extends State<SubsystemStatusDisplay> {

  bool _isPanelExpanded = false;

  static const String _defaultMessage = "No message.";

  String get _message => switch (widget.status) {
        SubsystemStatusInitial() => '',
        SubsystemStatusBusy(:final message) => message,
        SubsystemStatusOk(:final message) => message ?? _defaultMessage,
        SubsystemStatusDisabled() => 'This component is disabled.',
        SubsystemStatusWarning(:final message) => message,
        SubsystemStatusError(:final message) => message,
        SubsystemStatusWithChildren() => '',
      };

  ActionMap get _actions => switch (widget.status) {
        SubsystemStatusInitial() => const {},
        SubsystemStatusBusy(:final actions) => actions,
        SubsystemStatusOk(:final actions) => actions,
        SubsystemStatusDisabled(:final actions) => actions,
        SubsystemStatusWarning(:final actions) => actions,
        SubsystemStatusError(:final actions) => actions,
        SubsystemStatusWithChildren(:final actions) => actions,
      };

  String? get _exception => switch (widget.status) {
        SubsystemStatusError(:final exception) => exception,
        _ => null,
      };

  bool get _canExpand => _actions.isNotEmpty || _exception != null;

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      alignment: Alignment.topCenter,
      duration: Duration(milliseconds: 200),
      curve: Curves.ease,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            leading: SubsystemStatusIcon(status: widget.status),
            title: Text(widget.title),
            subtitle: Text(_message),
            trailing: _canExpand ? AnimatedRotation(
              turns: _isPanelExpanded ? 0.25 : 0,
              duration: Duration(milliseconds: 200),
              curve: Curves.ease,
              child: Icon(LucideIcons.chevronRight),
            ) : null,
            onPressed: _canExpand ? () => setState(() => _isPanelExpanded = !_isPanelExpanded) : null,
          ),
          if (_canExpand && _isPanelExpanded)
            Container(
              decoration: BoxDecoration(border: Border(left: BorderSide(color: Colors.black))),
              margin: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                spacing: 8,
                children: [
                  if (_exception != null) Text(_exception!),
                  for (var entry in _actions.entries) HyperlinkButton(onPressed: entry.value, child: Text(entry.key)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
