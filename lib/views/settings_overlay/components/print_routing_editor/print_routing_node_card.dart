import 'package:fl_nodes_v2/fl_nodes_v2.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:momento_booth/hardware_control/printing/print_routing_analysis.dart';
import 'package:momento_booth/models/print_queue_info.dart';
import 'package:momento_booth/models/print_routing_graph.dart';
import 'package:momento_booth/views/settings_overlay/components/print_routing_editor/print_calibration_dialog.dart';
import 'package:momento_booth/views/settings_overlay/components/print_routing_editor/print_routing_editor_view_model.dart';
import 'package:momento_booth/views/settings_overlay/components/print_routing_editor/print_routing_node_layout.dart';

/// The body of a node on the print routing canvas. Its rows follow [RoutingNodeLayout], which the port anchors are
/// derived from.
class RoutingNodeCard extends StatelessWidget {

  final GraphNode node;
  final NodeRenderState state;
  final PrintRoutingEditorViewModel viewModel;

  const RoutingNodeCard({super.key, required this.node, required this.state, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final data = node.field<RoutingNodeData>(routingDataKey);
    if (data == null) return const SizedBox.shrink();

    final theme = FluentTheme.of(context);
    final resources = theme.resources;
    final bool marginsWired = data is PrinterNodeData && state.isWired(RoutingPorts.margins);
    void update(RoutingNodeData newData) => viewModel.updateNodeData(node.id, newData);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: resources.solidBackgroundFillColorQuarternary,
        border: Border.all(
          color: state.isConnectionTarget ? theme.accentColor.defaultBrushFor(theme.brightness) : resources.cardStrokeColorDefault,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        // The node height is re-derived just after an edit that changes the notes, so the rows may briefly not fit.
        child: OverflowBox(
          alignment: Alignment.topCenter,
          minHeight: 0,
          maxHeight: double.infinity,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Header(data: data),
              ..._portRows(data),
              ...switch (data) {
                SourceNodeData() => const [],
                RoundRobinNodeData() || DuplicateNodeData() => [_CarriedTypeRow(nodeId: node.id, viewModel: viewModel)],
                TileLayoutNodeData() => _tileLayoutFields(data, update),
                StackNodeData() => _stackFields(data, update),
                MarginsNodeData(:final margins) => [
                  const _CaptionRow(child: _SecondaryCaption('Values in mm')),
                  _MarginsFields(margins: margins, onChanged: (margins) => update(data.copyWith(margins: margins))),
                ],
                // Whether native printers list their media is only known once the printers are loaded.
                PrinterNodeData() => [
                  Observer(builder: (_) => Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: _printerFields(data, update, marginsWired: marginsWired),
                  )),
                ],
              },
              _NoteRows(nodeId: node.id, viewModel: viewModel),
              const SizedBox(height: RoutingNodeMetrics.bottomPadding),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _portRows(RoutingNodeData data) {
    final layout = RoutingNodeLayout(data, marginsWired: false, noteRows: 0, canListNativeMedia: viewModel.canListNativeMedia);
    final inputs = layout.rowPorts(RoutingPortDirection.input);
    final outputs = layout.rowPorts(RoutingPortDirection.output);
    return [
      for (int row = 0; row < layout.portRows; row++)
        SizedBox(
          height: RoutingNodeMetrics.portRowHeight,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Expanded(child: _PortLabel(nodeId: node.id, data: data, port: row < inputs.length ? inputs[row] : null, viewModel: viewModel)),
                Expanded(child: _PortLabel(nodeId: node.id, data: data, port: row < outputs.length ? outputs[row] : null, viewModel: viewModel)),
              ],
            ),
          ),
        ),
    ];
  }

  List<Widget> _tileLayoutFields(TileLayoutNodeData data, ValueChanged<RoutingNodeData> update) => [
    _FieldRow(
      key: const ValueKey('columns'),
      label: 'Columns',
      child: NumberBox<int>(
        value: data.columns,
        min: 1,
        clearButton: false,
        mode: SpinButtonPlacementMode.inline,
        onChanged: (value) => update(data.copyWith(columns: value ?? data.columns)),
      ),
    ),
    _FieldRow(
      key: const ValueKey('rows'),
      label: 'Rows',
      child: NumberBox<int>(
        value: data.rows,
        min: 1,
        clearButton: false,
        mode: SpinButtonPlacementMode.inline,
        onChanged: (value) => update(data.copyWith(rows: value ?? data.rows)),
      ),
    ),
  ];

  List<Widget> _stackFields(StackNodeData data, ValueChanged<RoutingNodeData> update) => [
    _FieldRow(
      key: const ValueKey('mode'),
      label: 'Print',
      child: ComboBox<StackMode>(
        value: data.mode,
        isExpanded: true,
        items: const [
          ComboBoxItem(value: StackMode.direct, child: Text('Right away')),
          ComboBoxItem(value: StackMode.collect, child: Text('When full')),
        ],
        onChanged: (value) => update(data.copyWith(mode: value ?? data.mode)),
      ),
    ),
    if (data.mode == StackMode.collect)
      _FieldRow(
        key: const ValueKey('printAfterIdleMinutes'),
        label: 'Idle (min)',
        child: Tooltip(
          message: 'Also print a sheet that is not full once no copy was added for this many minutes. 0 waits for a full sheet.',
          child: NumberBox<int>(
            value: data.printAfterIdleMinutes,
            min: 0,
            clearButton: false,
            mode: SpinButtonPlacementMode.inline,
            onChanged: (value) => update(data.copyWith(printAfterIdleMinutes: value ?? data.printAfterIdleMinutes)),
          ),
        ),
      ),
    _FieldRow(
      key: const ValueKey('direction'),
      label: 'Fill',
      child: Tooltip(
        message: 'Columns fill the sheet from the top, with each copy turned to use the least height. '
            'Rows fill it from the left, with each copy turned to use the least width.',
        child: ComboBox<StackDirection>(
          value: data.direction,
          isExpanded: true,
          items: const [
            ComboBoxItem(value: StackDirection.columns, child: Text('Columns')),
            ComboBoxItem(value: StackDirection.rows, child: Text('Rows')),
          ],
          onChanged: (value) => update(data.copyWith(direction: value ?? data.direction)),
        ),
      ),
    ),
    _FieldRow(
      key: const ValueKey('lanes'),
      label: switch (data.direction) {
        StackDirection.columns => 'Columns',
        StackDirection.rows => 'Rows',
      },
      child: NumberBox<int>(
        value: data.lanes,
        min: 1,
        clearButton: false,
        mode: SpinButtonPlacementMode.inline,
        onChanged: (value) => update(data.copyWith(lanes: value ?? data.lanes)),
      ),
    ),
    _FieldRow(
      key: const ValueKey('gap'),
      label: 'Gap (mm)',
      child: _MillimeterBox(value: data.gap, onChanged: (value) => update(data.copyWith(gap: value))),
    ),
  ];

  List<Widget> _printerFields(PrinterNodeData data, ValueChanged<RoutingNodeData> update, {required bool marginsWired}) {
    final isCups = data.backend == PrinterBackend.cups;
    // Read first, so the observer around these fields always tracks it.
    final listsMedia = viewModel.canListNativeMedia || isCups;
    return [
      _FieldRow(
        key: const ValueKey('label'),
        label: 'Label',
        child: _SyncedTextBox(
          value: data.label,
          placeholder: 'Name of this configuration',
          editor: viewModel.editor,
          onChanged: (value) => update(data.copyWith(label: value)),
        ),
      ),
      _FieldRow(
        key: const ValueKey('backend'),
        label: 'Backend',
        child: ComboBox<PrinterBackend>(
          value: data.backend,
          isExpanded: true,
          items: const [
            ComboBoxItem(value: PrinterBackend.native, child: Text('Native')),
            ComboBoxItem(value: PrinterBackend.cups, child: Text('CUPS')),
          ],
          // The queues and media of one backend mean nothing to the other.
          onChanged: (value) {
            if (value != null && value != data.backend) update(RoutingNodeData.printer(label: data.label, backend: value, margins: data.margins, borderless: data.borderless));
          },
        ),
      ),
      _FieldRow(
        key: ValueKey('queue-${data.backend.name}'),
        label: isCups ? 'Queue' : 'Printer',
        child: Observer(builder: (_) => _QueueComboBox(
          queues: isCups ? viewModel.cupsQueues : viewModel.nativeQueues,
          queueId: data.queueId,
          // Media differ per queue, so a printer that lists its media has to pick it again.
          onChanged: (value) => update(listsMedia ? data.copyWith(queueId: value, media: const PrintMedia()) : data.copyWith(queueId: value)),
        )),
      ),
      if (listsMedia)
        _FieldRow(
          key: ValueKey('media-${data.backend.name}'),
          label: isCups ? 'Media' : 'Paper',
          child: _MediaComboBox(
            viewModel: viewModel,
            backend: data.backend,
            queueId: data.queueId,
            media: data.media,
            onChanged: (media) => update(data.copyWith(media: media)),
          ),
        ),
      _FieldRow(
        key: ValueKey('size-${data.backend.name}'),
        label: 'Size (mm)',
        child: listsMedia
            ? Text(
                data.media.widthMm > 0 ? 'W ${_formatMm(data.media.widthMm)} × H ${_formatMm(data.media.heightMm)}' : '–',
              )
            : Row(
                spacing: 6,
                children: [
                  const _SecondaryCaption('W'),
                  Expanded(
                    child: _MillimeterBox(
                      value: data.media.widthMm,
                      placeholder: 'Width',
                      // A size set by hand no longer identifies a media of the printer.
                      onChanged: (value) => update(data.copyWith(media: PrintMedia(widthMm: value, heightMm: data.media.heightMm))),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const _SecondaryCaption('H'),
                  Expanded(
                    child: _MillimeterBox(
                      value: data.media.heightMm,
                      placeholder: 'Height',
                      onChanged: (value) => update(data.copyWith(media: PrintMedia(widthMm: data.media.widthMm, heightMm: value))),
                    ),
                  ),
                ],
              ),
      ),
      _FieldRow(
        key: const ValueKey('borderless'),
        label: 'Borderless',
        child: Tooltip(
          message: 'Turn on when the printer prints up to the edge of the paper and cuts off what lies beyond the margins. '
              'The bleed of a photo (the collage padding) is then printed beyond the margins, so it is cut off. '
              'Turned off, the whole photo is printed within the margins, and its bleed is cut off by hand.',
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: ToggleSwitch(checked: data.borderless, onChanged: (value) => update(data.copyWith(borderless: value))),
          ),
        ),
      ),
      // The margins port sits on this row. Like an unconnected socket in Blender, the value is editable inline until a
      // margins node supplies it.
      _MarginsCaptionRow(nodeId: node.id, data: data, wired: marginsWired, viewModel: viewModel),
      if (!marginsWired)
        _MarginsFields(
          key: const ValueKey('margins'),
          margins: data.margins,
          onChanged: (margins) => update(data.copyWith(margins: margins)),
        ),
    ];
  }

}

String _formatMm(double value) => value == value.roundToDouble() ? value.toStringAsFixed(0) : value.toStringAsFixed(1);

class _Header extends StatelessWidget {

  final RoutingNodeData data;

  const _Header({required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final kind = RoutingNodeKind.of(data);
    return Container(
      height: RoutingNodeMetrics.headerHeight,
      color: routingNodeKindTint(kind),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        spacing: 8,
        children: [
          Icon(kind.icon, size: 16, color: kind.color.darker),
          Flexible(child: Text(kind.label, overflow: TextOverflow.ellipsis, style: theme.typography.bodyStrong)),
          if (data case PrinterNodeData(:final label) when label.isNotEmpty)
            Expanded(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: theme.typography.body?.copyWith(color: theme.resources.textFillColorSecondary),
              ),
            ),
        ],
      ),
    );
  }

}

class _PortLabel extends StatelessWidget {

  final String nodeId;
  final RoutingNodeData data;
  final RoutingPortSpec? port;
  final PrintRoutingEditorViewModel viewModel;

  const _PortLabel({required this.nodeId, required this.data, required this.port, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final port = this.port;
    if (port == null) return const SizedBox.shrink();

    Widget label(BuildContext context) => Text(
      routingPortLabel(data, port),
      textAlign: port.direction == RoutingPortDirection.input ? TextAlign.left : TextAlign.right,
      overflow: TextOverflow.ellipsis,
      style: FluentTheme.of(context).typography.caption?.copyWith(color: routingPortTypeColor(viewModel.portType(nodeId, port))),
    );
    // Only ports without a single fixed type follow what flows through them.
    final bool hasFixedType = !port.isPassthrough && port.types.length == 1;
    return hasFixedType ? label(context) : Observer(builder: label);
  }

}

class _FieldRow extends StatelessWidget {

  final String label;
  final Widget child;

  const _FieldRow({super.key, required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: RoutingNodeMetrics.fieldRowHeight,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Row(
          children: [
            SizedBox(width: 72, child: Text(label, style: FluentTheme.of(context).typography.caption)),
            Expanded(child: _DragBarrier(child: child)),
          ],
        ),
      ),
    );
  }

}

/// Keeps a drag that starts on a field from moving the node. Text boxes claim such a drag for text selection
/// themselves, as they are deeper in the tree.
class _DragBarrier extends StatelessWidget {

  final Widget child;

  const _DragBarrier({required this.child});

  @override
  Widget build(BuildContext context) => GestureDetector(onPanStart: (_) {}, child: child);

}

class _SecondaryCaption extends StatelessWidget {

  final String text;

  const _SecondaryCaption(this.text);

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return Text(
      text,
      overflow: TextOverflow.ellipsis,
      style: theme.typography.caption?.copyWith(color: theme.resources.textFillColorSecondary),
    );
  }

}

class _CaptionRow extends StatelessWidget {

  final Widget child;

  const _CaptionRow({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: RoutingNodeMetrics.captionRowHeight,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Align(alignment: Alignment.centerLeft, child: child),
      ),
    );
  }

}

class _CarriedTypeRow extends StatelessWidget {

  final String nodeId;
  final PrintRoutingEditorViewModel viewModel;

  const _CarriedTypeRow({required this.nodeId, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return _CaptionRow(
      child: Observer(builder: (context) {
        final type = viewModel.analysis.arbiterTypes[nodeId];
        return Text(
          switch (type) {
            RoutingPortType.photo => 'Carries photos',
            RoutingPortType.sheet => 'Carries sheets',
            // Arbiters do not accept stacks.
            RoutingPortType.stack => 'Carries stacks',
            RoutingPortType.margins || null => 'Carries nothing yet',
          },
          style: theme.typography.caption?.copyWith(color: theme.resources.textFillColorSecondary),
        );
      }),
    );
  }

}

class _MarginsCaptionRow extends StatelessWidget {

  final String nodeId;
  final PrinterNodeData data;
  final bool wired;
  final PrintRoutingEditorViewModel viewModel;

  const _MarginsCaptionRow({required this.nodeId, required this.data, required this.wired, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return _CaptionRow(
      key: const ValueKey('marginsCaption'),
      child: Row(
        spacing: 8,
        children: [
          Text(
            'Margins',
            style: theme.typography.caption?.copyWith(color: routingPortTypeColor(RoutingPortType.margins)),
          ),
          Expanded(child: _SecondaryCaption(wired ? 'from the connected node' : 'in mm')),
          if (!wired)
            Tooltip(
              message: 'Move these margins to a new margins node, to share them with other printers',
              child: IconButton(
                key: const ValueKey('moveMarginsToNode'),
                icon: Icon(RoutingNodeKind.margins.icon, size: 14),
                style: const ButtonStyle(padding: WidgetStatePropertyAll(EdgeInsets.all(4))),
                onPressed: () => viewModel.moveMarginsToNode(nodeId),
              ),
            ),
          Tooltip(
            message: PrintRoutingEditorViewModelBase.canCalibrate(data)
                ? 'Print a calibration page, to measure the margins'
                : 'Choose a printer and media first, to print a calibration page',
            child: IconButton(
              key: const ValueKey('calibrate'),
              icon: const Icon(LucideIcons.ruler, size: 14),
              style: const ButtonStyle(padding: WidgetStatePropertyAll(EdgeInsets.all(4))),
              onPressed: PrintRoutingEditorViewModelBase.canCalibrate(data)
                  ? () => showPrintCalibrationDialog(context, viewModel: viewModel, nodeId: nodeId)
                  : null,
            ),
          ),
        ],
      ),
    );
  }

}

class _MarginsFields extends StatelessWidget {

  final PrintMargins margins;
  final ValueChanged<PrintMargins> onChanged;

  const _MarginsFields({super.key, required this.margins, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    Widget box(String label, double value, PrintMargins Function(double value) apply) => Expanded(
      child: Row(
        spacing: 6,
        children: [
          SizedBox(width: 44, child: Text(label, style: FluentTheme.of(context).typography.caption)),
          Expanded(child: _DragBarrier(child: _MillimeterBox(value: value, onChanged: (value) => onChanged(apply(value))))),
        ],
      ),
    );

    Widget row(List<Widget> children) => SizedBox(
      height: RoutingNodeMetrics.fieldRowHeight,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Row(spacing: 12, children: children),
      ),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        row([
          box('Top', margins.top, (value) => margins.copyWith(top: value)),
          box('Right', margins.right, (value) => margins.copyWith(right: value)),
        ]),
        row([
          box('Bottom', margins.bottom, (value) => margins.copyWith(bottom: value)),
          box('Left', margins.left, (value) => margins.copyWith(left: value)),
        ]),
      ],
    );
  }

}

class _NoteRows extends StatelessWidget {

  final String nodeId;
  final PrintRoutingEditorViewModel viewModel;

  const _NoteRows({required this.nodeId, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return Observer(builder: (context) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final note in viewModel.notesOf(nodeId))
          SizedBox(
            height: RoutingNodeMetrics.noteRowHeight,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Tooltip(
                message: note.text,
                child: Row(
                  spacing: 6,
                  children: [
                    Icon(routingNoteIcon(note.severity), size: 14, color: routingNoteColor(context, note.severity)),
                    Expanded(
                      child: Text(
                        note.text,
                        overflow: TextOverflow.ellipsis,
                        style: theme.typography.caption?.copyWith(color: routingNoteColor(context, note.severity)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    ));
  }

}

IconData routingNoteIcon(RoutingIssueSeverity? severity) => switch (severity) {
  RoutingIssueSeverity.error => LucideIcons.circleAlert,
  RoutingIssueSeverity.warning => LucideIcons.triangleAlert,
  null => LucideIcons.info,
};

Color routingNoteColor(BuildContext context, RoutingIssueSeverity? severity) {
  final resources = FluentTheme.of(context).resources;
  return switch (severity) {
    RoutingIssueSeverity.error => resources.systemFillColorCritical,
    RoutingIssueSeverity.warning => resources.systemFillColorCaution,
    null => resources.textFillColorSecondary,
  };
}

class _MillimeterBox extends StatelessWidget {

  final double value;
  final String? placeholder;
  final ValueChanged<double> onChanged;

  const _MillimeterBox({required this.value, this.placeholder, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return NumberBox<double>(
      value: value,
      min: 0,
      smallChange: 0.5,
      placeholder: placeholder,
      clearButton: false,
      mode: SpinButtonPlacementMode.none,
      onChanged: (newValue) {
        if (newValue != null && newValue != value) onChanged(newValue);
      },
    );
  }

}

class _QueueComboBox extends StatelessWidget {

  final List<PrintQueueInfo> queues;
  final String queueId;
  final ValueChanged<String> onChanged;

  const _QueueComboBox({required this.queues, required this.queueId, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return ComboBox<String>(
      value: queueId.isEmpty ? null : queueId,
      isExpanded: true,
      placeholder: const Text('Select'),
      items: [
        for (final queue in queues) ComboBoxItem(value: queue.id, child: Text(queue.name, overflow: TextOverflow.ellipsis)),
        if (queueId.isNotEmpty && !queues.any((queue) => queue.id == queueId))
          ComboBoxItem(value: queueId, child: Text('$queueId (not found)', overflow: TextOverflow.ellipsis)),
      ],
      onChanged: (value) {
        if (value != null && value != queueId) onChanged(value);
      },
    );
  }

}

/// Chooses from the media a CUPS queue or a native printer lists, e.g. the papers of its Windows driver.
class _MediaComboBox extends StatelessWidget {

  final PrintRoutingEditorViewModel viewModel;
  final PrinterBackend backend;
  final String queueId;
  final PrintMedia media;
  final ValueChanged<PrintMedia> onChanged;

  const _MediaComboBox({required this.viewModel, required this.backend, required this.queueId, required this.media, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    viewModel.ensureMedia(backend, queueId);
    final isCups = backend == PrinterBackend.cups;
    return Observer(builder: (context) {
      final available = viewModel.media[(backend, queueId)] ?? const [];
      return ComboBox<String>(
        value: media.name.isEmpty ? null : media.name,
        isExpanded: true,
        placeholder: Text(queueId.isEmpty ? (isCups ? 'Select a queue first' : 'Select a printer first') : 'Select'),
        items: [
          for (final dimension in available)
            ComboBoxItem(value: dimension.keyword, child: Text(dimension.name, overflow: TextOverflow.ellipsis)),
          if (media.name.isNotEmpty && !available.any((dimension) => dimension.keyword == media.name))
            ComboBoxItem(
              value: media.name,
              child: Text(
                isCups ? '${media.name} (not found)' : 'Paper ${media.name} (not found)',
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
        onChanged: (keyword) {
          final dimension = available.where((dimension) => dimension.keyword == keyword).firstOrNull;
          if (dimension == null || keyword == media.name) return;
          onChanged(PrintMedia(name: dimension.keyword, widthMm: dimension.width, heightMm: dimension.height));
        },
      );
    });
  }

}

/// A [TextBox] that writes every keystroke to the graph, folded into one undo step per focus session, and adopts
/// changes from the graph (undo, redo) while it does not have focus.
class _SyncedTextBox extends StatefulWidget {

  final String value;
  final String? placeholder;
  final NodeEditorController editor;
  final ValueChanged<String> onChanged;

  const _SyncedTextBox({required this.value, this.placeholder, required this.editor, required this.onChanged});

  @override
  State<_SyncedTextBox> createState() => _SyncedTextBoxState();

}

class _SyncedTextBoxState extends State<_SyncedTextBox> {

  late final TextEditingController _controller = TextEditingController(text: widget.value);
  final FocusNode _focusNode = FocusNode();
  bool _inTransaction = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void didUpdateWidget(_SyncedTextBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_focusNode.hasFocus && widget.value != _controller.text) _controller.text = widget.value;
  }

  @override
  void dispose() {
    _endTransaction();
    _focusNode
      ..removeListener(_onFocusChanged)
      ..dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (!_focusNode.hasFocus) _endTransaction();
  }

  void _endTransaction() {
    if (!_inTransaction) return;
    _inTransaction = false;
    widget.editor.history.commitTransaction();
  }

  void _onChanged(String text) {
    if (!_inTransaction) {
      _inTransaction = true;
      widget.editor.history.beginTransaction();
    }
    widget.onChanged(text);
  }

  @override
  Widget build(BuildContext context) {
    return TextBox(
      controller: _controller,
      focusNode: _focusNode,
      placeholder: widget.placeholder,
      onChanged: _onChanged,
    );
  }

}
