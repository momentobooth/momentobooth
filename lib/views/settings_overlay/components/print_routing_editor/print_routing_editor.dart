import 'dart:async';

import 'package:collection/collection.dart';
import 'package:fl_nodes_v2/fl_nodes_v2.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:momento_booth/hardware_control/printing/print_routing_analysis.dart';
import 'package:momento_booth/models/print_routing_graph.dart';
import 'package:momento_booth/models/settings.dart';
import 'package:momento_booth/views/settings_overlay/components/print_routing_editor/print_routing_editor_view_model.dart';
import 'package:momento_booth/views/settings_overlay/components/print_routing_editor/print_routing_hardware.dart';
import 'package:momento_booth/views/settings_overlay/components/print_routing_editor/print_routing_node_card.dart';
import 'package:momento_booth/views/settings_overlay/components/print_routing_editor/print_routing_node_layout.dart';
import 'package:momento_booth/views/settings_overlay/components/print_routing_editor/print_routing_notes.dart';

/// Node editor for the [PrintRoutingGraph], with an overview of the routes and problems next to it.
///
/// [initialGraph] is only read once. Edits are reported through [onGraphChanged] once they settle.
class PrintRoutingEditor extends StatefulWidget {

  final PrintRoutingGraph initialGraph;
  final ValueChanged<PrintRoutingGraph> onGraphChanged;
  final PrintRoutingHardware hardware;

  const PrintRoutingEditor({
    super.key,
    required this.initialGraph,
    required this.onGraphChanged,
    this.hardware = const SystemPrintRoutingHardware(),
  });

  @override
  State<PrintRoutingEditor> createState() => _PrintRoutingEditorState();

}

class _PrintRoutingEditorState extends State<PrintRoutingEditor> {

  late final PrintRoutingEditorViewModel _viewModel = PrintRoutingEditorViewModel(
    widget.initialGraph,
    onGraphChanged: widget.onGraphChanged,
    hardware: widget.hardware,
  );
  final GlobalKey<NodeEditorState> _editorKey = GlobalKey();
  final FlyoutController _menuController = FlyoutController();

  /// Held once: the editor compares node builders by identity, and a new closure per build rebuilds every node.
  late final NodeWidgetBuilder _nodeBuilder = _buildNode;

  /// A wire takes the colour of the type it carries. Static, as a new function per build repaints every wire.
  static ConnectionAppearance _connectionAppearance(NodeConnection connection, NodePort from, NodePort to) =>
      ConnectionAppearance(color: from.color);

  NodeEditorController get _editor => _viewModel.editor;

  @override
  void initState() {
    super.initState();
    unawaited(_viewModel.loadQueues());
    WidgetsBinding.instance.addPostFrameCallback((_) => _editorKey.currentState?.fitToContent());
  }

  @override
  void dispose() {
    _menuController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  Widget _buildNode(BuildContext context, GraphNode node, NodeRenderState state) =>
      RoutingNodeCard(node: node, state: state, viewModel: _viewModel);

  int _nodesAddedFromToolbar = 0;

  void _addNodeInView(RoutingNodeKind kind) {
    final editorState = _editorKey.currentState;
    if (editorState == null) return;
    final center = _editor.camera.viewport.toScene(editorState.viewportSize.center(Offset.zero));
    // Successive nodes are offset a little, so they do not land exactly on top of each other.
    final cascade = const Offset(24, 24) * (_nodesAddedFromToolbar++ % 6).toDouble();
    _viewModel.addNode(kind, center - Offset(kind.width / 2, 60) + cascade);
  }

  void _focusNode(String nodeId) {
    if (!_editor.graph.nodes.containsKey(nodeId)) return;
    _editor.selection.selectNode(nodeId);
    final editorState = _editorKey.currentState;
    if (editorState != null) _editor.camera.centerOnNode(nodeId, editorState.viewportSize);
  }

  // ///////////// //
  // Context menus //
  // ///////////// //

  void _showMenu(Offset globalPosition, List<MenuFlyoutItemBase> items) {
    final navigatorBox = Navigator.of(context).context.findRenderObject()! as RenderBox;
    unawaited(_menuController.showFlyout(
      position: navigatorBox.globalToLocal(globalPosition),
      barrierColor: Colors.transparent,
      builder: (context) => MenuFlyout(items: items),
    ));
  }

  void _onCanvasSecondaryTap(Offset scenePosition, Offset globalPosition) {
    _showMenu(globalPosition, [
      for (final kind in RoutingNodeKind.values)
        if (kind != RoutingNodeKind.source)
          MenuFlyoutItem(
            leading: Icon(kind.icon, color: kind.color.darker),
            text: Text('Add ${kind.label.toLowerCase()}'),
            onPressed: () => _viewModel.addNode(kind, scenePosition),
          ),
    ]);
  }

  void _onNodeSecondaryTap(GraphNode node, Offset globalPosition) {
    final routingNode = _viewModel.graph.nodes.firstWhereOrNull((routingNode) => routingNode.id == node.id);
    if (routingNode == null || routingNode.data is SourceNodeData) return;
    _showMenu(globalPosition, [
      MenuFlyoutItem(
        leading: const Icon(LucideIcons.trash2),
        text: Text('Delete ${RoutingNodeKind.of(routingNode.data).label.toLowerCase()}'),
        onPressed: () => _viewModel.removeNode(node.id),
      ),
    ]);
  }

  void _onConnectionSecondaryTap(NodeConnection connection, Offset globalPosition) {
    _showMenu(globalPosition, [
      MenuFlyoutItem(
        leading: const Icon(LucideIcons.unplug),
        text: const Text('Delete connection'),
        onPressed: () => _viewModel.removeConnections([connection.id]),
      ),
    ]);
  }

  void _onPortSecondaryTap(PortRef port, Offset globalPosition) {
    final connections = _editor.graph.connectionsAt(port).toList();
    if (connections.isEmpty) return;
    _showMenu(globalPosition, [
      MenuFlyoutItem(
        leading: const Icon(LucideIcons.unplug),
        text: Text(connections.length == 1 ? 'Disconnect' : 'Disconnect ${connections.length} connections'),
        onPressed: () => _viewModel.removeConnections(connections.map((connection) => connection.id)),
      ),
    ]);
  }

  // ////// //
  // Layout //
  // ////// //

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 8,
      children: [
        _Toolbar(editor: _editor, onFitView: () => _editorKey.currentState?.fitToContent(), onAddNode: _addNodeInView),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 16,
            children: [
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(color: theme.resources.cardStrokeColorDefault),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Listener(
                      onPointerUp: (_) => _viewModel.clearConnectionHint(),
                      onPointerCancel: (_) => _viewModel.clearConnectionHint(),
                      child: FlyoutTarget(
                        controller: _menuController,
                        child: NodeEditor(
                          key: _editorKey,
                          controller: _editor,
                          nodeBuilder: _nodeBuilder,
                          theme: _editorTheme(theme),
                          connectionAppearance: _connectionAppearance,
                          // The built-in menus are Material MenuAnchors; Fluent flyouts are opened from the callbacks.
                          contextMenus: null,
                          onCanvasSecondaryTap: _onCanvasSecondaryTap,
                          onNodeSecondaryTap: _onNodeSecondaryTap,
                          onConnectionSecondaryTap: _onConnectionSecondaryTap,
                          onPortSecondaryTap: _onPortSecondaryTap,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 280, child: _SidePanel(viewModel: _viewModel, onNodePressed: _focusNode)),
            ],
          ),
        ),
        _StatusLine(viewModel: _viewModel),
      ],
    );
  }

  static NodeEditorTheme _editorTheme(FluentThemeData theme) {
    final resources = theme.resources;
    return NodeEditorTheme.light(accent: theme.accentColor.defaultBrushFor(theme.brightness)).copyWith(
      background: resources.solidBackgroundFillColorBase,
      gridLine: resources.dividerStrokeColorDefault,
      gridLineMajor: resources.controlStrokeColorDefault,
      connectionColor: resources.textFillColorTertiary,
      hoveredConnectionColor: resources.textFillColorPrimary,
      invalidConnectionColor: resources.systemFillColorCritical,
      portColor: resources.textFillColorSecondary,
      portBorderColor: resources.solidBackgroundFillColorBase,
    );
  }

}

class _Toolbar extends StatelessWidget {

  final NodeEditorController editor;
  final VoidCallback onFitView;
  final ValueChanged<RoutingNodeKind> onAddNode;

  const _Toolbar({required this.editor, required this.onFitView, required this.onAddNode});

  @override
  Widget build(BuildContext context) {
    final history = editor.history;
    // Listens to the controller for the toolbar only; the editor itself must not be rebuilt by its own controller.
    return ListenableBuilder(
      listenable: editor,
      builder: (context, _) => Row(
        spacing: 8,
        children: [
          Button(
            onPressed: history.canUndo ? history.undo : null,
            child: const Row(spacing: 6, children: [Icon(LucideIcons.undo2, size: 16), Text('Undo')]),
          ),
          Button(
            onPressed: history.canRedo ? history.redo : null,
            child: const Row(spacing: 6, children: [Icon(LucideIcons.redo2, size: 16), Text('Redo')]),
          ),
          Button(
            onPressed: onFitView,
            child: const Row(spacing: 6, children: [Icon(LucideIcons.scan, size: 16), Text('Fit view')]),
          ),
          const SizedBox(height: 24, child: Divider(direction: Axis.vertical)),
          for (final kind in RoutingNodeKind.values)
            if (kind != RoutingNodeKind.source) _AddNodeButton(kind: kind, onPressed: () => onAddNode(kind)),
        ],
      ),
    );
  }

}

class _AddNodeButton extends StatelessWidget {

  final RoutingNodeKind kind;
  final VoidCallback onPressed;

  const _AddNodeButton({required this.kind, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Add a ${kind.label.toLowerCase()} node in the middle of the view',
      child: Button(
        style: ButtonStyle(
          // In the colours of the node header, a little stronger on interaction.
          backgroundColor: WidgetStateProperty.resolveWith((states) => switch (states) {
            _ when states.contains(WidgetState.pressed) => kind.tintBase.withValues(alpha: 0.32),
            _ when states.contains(WidgetState.hovered) => kind.tintBase.withValues(alpha: 0.22),
            _ => routingNodeKindTint(kind),
          }),
        ),
        onPressed: onPressed,
        child: Row(spacing: 6, children: [Icon(kind.icon, size: 16, color: kind.color.darker), Text(kind.label)]),
      ),
    );
  }

}

class _SidePanel extends StatelessWidget {

  final PrintRoutingEditorViewModel viewModel;
  final ValueChanged<String> onNodePressed;

  const _SidePanel({required this.viewModel, required this.onNodePressed});

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return Observer(builder: (context) {
      final graph = viewModel.graph;
      final analysis = viewModel.analysis;
      final problems = analysis.issues.where((issue) => issue.kind != RoutingIssueKind.unroutedPrintSize).toList();

      String printerName(String nodeId) => switch (graph.nodes.firstWhereOrNull((node) => node.id == nodeId)?.data) {
        PrinterNodeData(:final label) when label.isNotEmpty => label,
        _ => 'Unnamed printer',
      };

      return ListView(
        children: [
          Text('Routes', style: theme.typography.bodyStrong),
          const SizedBox(height: 4),
          for (final size in PrintSize.values)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: 64, child: Text(printSizeShortLabel(size))),
                  Expanded(
                    child: Text(
                      switch (analysis.reachablePrinterIds[size]!) {
                        final printers when printers.isEmpty => 'Not printed',
                        final printers => printers.map(printerName).join(', '),
                      },
                      style: theme.typography.body?.copyWith(color: theme.resources.textFillColorSecondary),
                    ),
                  ),
                ],
              ),
            ),
          if (!analysis.hasConfiguredPrinter)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Printing stays disabled until a printer is set up: select a printer and its media in a printer node.',
                style: theme.typography.caption?.copyWith(color: theme.resources.textFillColorSecondary),
              ),
            ),
          const SizedBox(height: 16),
          Text('Problems', style: theme.typography.bodyStrong),
          const SizedBox(height: 4),
          if (problems.isEmpty)
            Text('None', style: theme.typography.body?.copyWith(color: theme.resources.textFillColorSecondary)),
          for (final issue in problems)
            ListTile(
              leading: Icon(routingNoteIcon(issue.severity), size: 16, color: routingNoteColor(context, issue.severity)),
              title: Text(routingIssueSubject(issue, graph) ?? describeRoutingIssue(issue, graph), style: theme.typography.body),
              subtitle: routingIssueSubject(issue, graph) == null
                  ? null
                  : Text(describeRoutingIssue(issue, graph), style: theme.typography.caption),
              onPressed: switch (issue.nodeId ?? issue.edge?.toNode) {
                final nodeId? => () => onNodePressed(nodeId),
                null => null,
              },
            ),
          const SizedBox(height: 16),
          Text('Printers', style: theme.typography.bodyStrong),
          const SizedBox(height: 4),
          Text(
            'The printers, CUPS queues and media to choose from are listed when this page opens.',
            style: theme.typography.caption?.copyWith(color: theme.resources.textFillColorSecondary),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Button(
              onPressed: viewModel.isRefreshingPrinters ? null : viewModel.refreshPrinters,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: 6,
                children: [
                  if (viewModel.isRefreshingPrinters)
                    const SizedBox.square(dimension: 16, child: ProgressRing(strokeWidth: 2))
                  else
                    const Icon(LucideIcons.refreshCw, size: 16),
                  const Text('Refresh printers'),
                ],
              ),
            ),
          ),
        ],
      );
    });
  }

}

class _StatusLine extends StatelessWidget {

  final PrintRoutingEditorViewModel viewModel;

  const _StatusLine({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return Observer(builder: (context) {
      final hint = viewModel.connectionHint;
      final color = hint == null ? theme.resources.textFillColorSecondary : theme.resources.systemFillColorCaution;
      return Row(
        spacing: 8,
        children: [
          Icon(hint == null ? LucideIcons.info : LucideIcons.triangleAlert, size: 14, color: color),
          Expanded(
            child: Text(
              hint ??
                  'Right-click the canvas to add a node, or a node or connection to remove it. Drag from a port to '
                      'connect. Ctrl+Z and Ctrl+Y undo and redo, the mouse wheel zooms, middle mouse or space+drag pans.',
              style: theme.typography.caption?.copyWith(color: color),
            ),
          ),
        ],
      );
    });
  }

}
