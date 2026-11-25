import 'package:fluent_ui/fluent_ui.dart';
import 'package:momento_booth/hardware_control/printing/print_calibration.dart';
import 'package:momento_booth/models/print_routing_graph.dart';
import 'package:momento_booth/views/settings_overlay/components/print_routing_editor/print_routing_editor_view_model.dart';

/// Asks for the length of the rulers and prints a calibration page on the printer of node [nodeId].
Future<void> showPrintCalibrationDialog(BuildContext context, {required PrintRoutingEditorViewModel viewModel, required String nodeId}) =>
    showDialog(context: context, builder: (_) => PrintCalibrationDialog(viewModel: viewModel, nodeId: nodeId));

/// Prints a calibration page, see [renderCalibrationPdf], and tells how to read it.
class PrintCalibrationDialog extends StatefulWidget {

  final PrintRoutingEditorViewModel viewModel;
  final String nodeId;

  const PrintCalibrationDialog({super.key, required this.viewModel, required this.nodeId});

  @override
  State<PrintCalibrationDialog> createState() => _PrintCalibrationDialogState();

}

class _PrintCalibrationDialogState extends State<PrintCalibrationDialog> {

  // The next calibration, e.g. of another printer of the same kind, likely wants the same length.
  static double _lastRulerLength = defaultCalibrationRulerLength;

  double _rulerLength = _lastRulerLength;
  bool _printing = false;
  String? _error;

  Future<void> _print() async {
    setState(() {
      _printing = true;
      _error = null;
    });
    _lastRulerLength = _rulerLength;
    try {
      await widget.viewModel.printCalibrationPage(widget.nodeId, rulerLength: _rulerLength);
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      if (mounted) {
        setState(() {
          _printing = false;
          _error = '$error';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final printer = widget.viewModel.graph.nodes.firstWhere((node) => node.id == widget.nodeId).data as PrinterNodeData;
    return ContentDialog(
      constraints: const BoxConstraints(maxWidth: 480),
      title: const Text('Print calibration page'),
      content: SingleChildScrollView(
        child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12,
        children: [
          Text(
            'Prints a page on ${printer.label.isEmpty ? printer.queueId : printer.label} '
            '(${widget.viewModel.mediaLabelOf(printer)}), with a ruler from the middle of every edge. On every side, the '
            'first ruler mark you can see is the margin of that side. Enter these margins at the printer, or at the '
            'margins node it uses.',
          ),
          InfoLabel(
            label: 'Ruler length (mm)',
            child: NumberBox<double>(
              value: _rulerLength,
              min: 5,
              max: 100,
              smallChange: 5,
              clearButton: false,
              mode: SpinButtonPlacementMode.inline,
              onChanged: _printing ? null : (value) => setState(() => _rulerLength = value ?? _rulerLength),
              // The value is only committed when the box loses focus, which pressing Print may not do.
              onTextChange: (text) {
                if (double.tryParse(text) case final value? when value >= 5 && value <= 100) _rulerLength = value;
              },
            ),
          ),
          Text(
            'Longer rulers measure larger margins, but leave less room for the rest of the page.',
            style: theme.typography.caption?.copyWith(color: theme.resources.textFillColorSecondary),
          ),
          if (_error case final error?) InfoBar(title: const Text('Could not print'), content: Text(error), severity: InfoBarSeverity.error),
        ],
        ),
      ),
      actions: [
        Button(onPressed: _printing ? null : () => Navigator.of(context).pop(), child: const Text('Cancel')),
        FilledButton(
          onPressed: _printing ? null : _print,
          child: _printing ? const SizedBox.square(dimension: 16, child: ProgressRing(strokeWidth: 2)) : const Text('Print'),
        ),
      ],
    );
  }

}
