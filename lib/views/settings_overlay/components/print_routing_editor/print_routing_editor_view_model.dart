import 'dart:async';
import 'dart:ui' show Offset;

import 'package:collection/collection.dart';
import 'package:fl_nodes_v2/fl_nodes_v2.dart';
import 'package:flutter/foundation.dart';
import 'package:mobx/mobx.dart';
import 'package:momento_booth/hardware_control/printing/print_routing_analysis.dart';
import 'package:momento_booth/models/print_queue_info.dart';
import 'package:momento_booth/models/print_routing_graph.dart';
import 'package:momento_booth/src/rust/utils/ipp_client.dart';
import 'package:momento_booth/utils/logger.dart';
import 'package:momento_booth/views/settings_overlay/components/print_routing_editor/print_routing_hardware.dart';
import 'package:momento_booth/views/settings_overlay/components/print_routing_editor/print_routing_node_layout.dart';
import 'package:momento_booth/views/settings_overlay/components/print_routing_editor/print_routing_notes.dart';

part 'print_routing_editor_view_model.g.dart';

/// State of the print routing editor.
///
/// While editing, the library's [editor] controller owns the graph: every edit, including undo and redo, goes through
/// it, and [graph] is derived from it after each change. Our [PrintRoutingGraph] is therefore always in sync, but never
/// written to directly.
class PrintRoutingEditorViewModel = PrintRoutingEditorViewModelBase with _$PrintRoutingEditorViewModel;

abstract class PrintRoutingEditorViewModelBase with Store, Logger implements RoutingNodeShapeSource {

  /// How long the graph has to stay unchanged before it is saved, so dragging and typing do not save on every frame.
  static const Duration saveDelay = Duration(milliseconds: 500);

  final ValueChanged<PrintRoutingGraph> onGraphChanged;
  final PrintRoutingHardware hardware;

  late final NodeEditorController editor = NodeEditorController(
    graph: toNodeGraph(graph),
    definitions: routingNodeDefinitions(this),
    connectionValidator: _validateConnection,
  );

  @observable
  PrintRoutingGraph graph;

  /// Analysis of [graph]. Not recomputed for edits that only move nodes.
  @observable
  PrintRoutingAnalysis analysis;

  /// Why the connection being drawn is refused, when the port colours do not already tell.
  @observable
  String? connectionHint;

  @observable
  ObservableList<PrintQueueInfo> nativeQueues = ObservableList();

  @observable
  ObservableList<PrintQueueInfo> cupsQueues = ObservableList();

  /// Whether native printers list their papers, so their media is chosen like that of CUPS queues.
  @override
  @observable
  bool canListNativeMedia = false;

  /// Media per backend and queue, loaded on first use by [ensureMedia].
  final ObservableMap<(PrinterBackend, String), List<PrintDimension>> media = ObservableMap();
  final Set<(PrinterBackend, String)> _requestedMedia = {};

  int _syncedRevision = -1;
  bool _disposed = false;
  bool _replacingConnections = false;
  Timer? _saveTimer;

  /// The last library graph a connection was validated against, and its conversion.
  (NodeGraph, PrintRoutingGraph)? _validationCache;

  /// What [portType] and [noteRows] answered when the nodes were last derived.
  List<Object?> _shapes;

  PrintRoutingEditorViewModelBase(
    PrintRoutingGraph initialGraph, {
    required this.onGraphChanged,
    this.hardware = const SystemPrintRoutingHardware(),
  }) : graph = initialGraph,
       analysis = PrintRoutingAnalysis.of(initialGraph),
       _shapes = const [] {
    _shapes = _currentShapes();
    editor
      ..guard = _guard
      ..onEdit = _onEdit
      ..addListener(_onEditorChanged);
    _onEditorChanged();
  }

  String? get sourceId => graph.nodes.firstWhereOrNull((node) => node.data is SourceNodeData)?.id;

  List<RoutingNodeNote> notesOf(String nodeId) => routingNodeNotes(analysis, graph, nodeId);

  void dispose() {
    _disposed = true;
    if (_saveTimer?.isActive ?? false) {
      _saveTimer!.cancel();
      onGraphChanged(graph);
    }
    editor
      ..removeListener(_onEditorChanged)
      ..dispose();
  }

  // /////////////// //
  // Editor to model //
  // /////////////// //

  void _onEditorChanged() {
    // Selection, hover and camera changes notify too, but do not bump the revision.
    if (editor.revision == _syncedRevision) return;
    final bool isInitial = _syncedRevision < 0;
    _syncedRevision = editor.revision;

    final next = toPrintRoutingGraph(editor.graph);
    if (next == graph) return;
    _sync(next);
    // Loading may drop invalid parts of the stored graph. That is only saved once the user edits the graph.
    if (!isInitial) _scheduleSave();
  }

  @action
  void _sync(PrintRoutingGraph next) {
    // Dragging a node changes the graph on every frame. Positions do not influence the analysis, so skip it then.
    final bool structureChanged = _withoutPositions(next) != _withoutPositions(graph);
    graph = next;
    if (!structureChanged) return;

    analysis = PrintRoutingAnalysis.of(next);
    final shapes = _currentShapes();
    if (const DeepCollectionEquality().equals(shapes, _shapes)) return;
    _shapes = shapes;
    // Port colours and notes follow from the whole graph, while the editor only re-derives the nodes an edit touched.
    // This is outside the undo history, as it updates the presentation rather than being an edit of its own.
    scheduleMicrotask(() {
      if (!_disposed) editor.revalidate();
    });
  }

  static PrintRoutingGraph _withoutPositions(PrintRoutingGraph graph) =>
      graph.copyWith(nodes: [for (final node in graph.nodes) node.copyWith(x: 0, y: 0)]);

  void _scheduleSave() {
    _saveTimer?.cancel();
    _saveTimer = Timer(saveDelay, () => onGraphChanged(graph));
  }

  /// Refuses edits the model cannot represent or allow.
  bool _guard(GraphEdit edit) => switch (edit.kind) {
    // Groups (Ctrl+G), comments, connection labels and waypoints cannot be stored. Refusing groups also keeps the
    // library's Material group dialogs unreachable.
    GraphEditKind.group || GraphEditKind.comment || GraphEditKind.labelConnection || GraphEditKind.routeConnection => false,
    // A graph has exactly one source. The editor's own commands leave it alone, as its definition is not deletable.
    GraphEditKind.removeNodes => !edit.nodeIds.contains(sourceId),
    _ => true,
  };

  /// Replaces the old connection of a single-connection port by the new one, as one undo step.
  void _onEdit(GraphEdit edit) {
    if (edit.kind != GraphEditKind.connect || _replacingConnections) return;

    for (final id in edit.connectionIds) {
      final connection = editor.graph.connections[id];
      if (connection == null) continue;
      final replaced = _replacedBy(connection);
      if (replaced.isEmpty) continue;

      _replacingConnections = true;
      try {
        if (editor.history.inTransaction) {
          editor.removeConnections(replaced);
        } else {
          editor.history
            ..undo()
            ..beginTransaction();
          editor
            ..removeConnections(replaced)
            ..connect(connection.from, connection.to, id: connection.id);
          editor.history.commitTransaction();
        }
      } finally {
        _replacingConnections = false;
      }
    }
  }

  /// The oldest connections at the ends of [connection] beyond the connection limits of those ports.
  List<String> _replacedBy(NodeConnection connection) {
    final List<String> replaced = [];
    for (final end in [connection.from, connection.to]) {
      final data = editor.graph.nodes[end.nodeId]?.field<RoutingNodeData>(routingDataKey);
      final maxConnections = data?.port(end.portId)?.maxConnections;
      if (maxConnections == null) continue;

      final others = [
        for (final existing in editor.graph.connectionsAt(end))
          if (existing.id != connection.id) existing.id,
      ];
      final excess = others.length - (maxConnections - 1);
      if (excess > 0) replaced.addAll(others.take(excess));
    }
    return replaced;
  }

  bool _validateConnection(ConnectionCheck check) {
    if (!check.allowedByDefault) return false;

    // Called for every candidate port while a wire is dragged, so convert each library graph only once.
    var cache = _validationCache;
    if (cache == null || !identical(cache.$1, check.graph)) {
      _validationCache = cache = (check.graph, toPrintRoutingGraph(check.graph));
    }
    final edge = RoutingEdge(
      fromNode: check.from.nodeId,
      fromPort: check.from.portId,
      toNode: check.to.nodeId,
      toPort: check.to.portId,
    );
    final issue = PrintRoutingAnalysis.checkConnection(cache.$2, edge);

    // The validator may run while the editor builds, so the hint is set afterwards.
    final hint = issue == null ? null : _hintFor(issue, edge, cache.$2);
    scheduleMicrotask(() {
      if (!_disposed && hint != connectionHint) runInAction(() => connectionHint = hint);
    });
    return issue == null;
  }

  /// Explains a refused connection when the port colours do not: an arbiter carries a single type, and connections
  /// cannot loop.
  String? _hintFor(RoutingIssue issue, RoutingEdge edge, PrintRoutingGraph graph) {
    if (issue.kind == RoutingIssueKind.cycle) return 'This connection would create a loop.';
    if (issue.kind != RoutingIssueKind.incompatibleTypes) return null;

    RoutingNodeData? dataOf(String? nodeId) => graph.nodes.firstWhereOrNull((node) => node.id == nodeId)?.data;
    if (dataOf(edge.fromNode) is StackNodeData && issue.edge == edge) {
      return 'A stack connects straight to a printer, as it fills sheets for the media of that printer.';
    }
    String kindOf(String? nodeId) => switch (dataOf(nodeId)) {
      final RoutingNodeData data => RoutingNodeKind.of(data).label.toLowerCase(),
      null => 'node',
    };

    if (issue.edge != edge) {
      return 'This would change what a ${kindOf(issue.edge?.fromNode)} carries, which breaks another of its connections.';
    }
    final fromType = analysis.arbiterTypes[edge.fromNode];
    // An arbiter takes the type of its single input, which a new connection replaces, so only what it sends on can
    // conflict.
    if ((dataOf(edge.fromNode)?.port(edge.fromPort)?.isPassthrough ?? false) && fromType != null) {
      return 'This ${kindOf(edge.fromNode)} carries ${_plural(fromType)}, which this input does not accept.';
    }
    return null;
  }

  static String _plural(RoutingPortType type) => switch (type) {
    RoutingPortType.photo => 'photos',
    RoutingPortType.sheet => 'sheets',
    RoutingPortType.stack => 'stacks',
    RoutingPortType.margins => 'margins',
  };

  @action
  void clearConnectionHint() => connectionHint = null;

  // ////////////////////// //
  // Node shapes and colors //
  // ////////////////////// //

  @override
  RoutingPortType? portType(String nodeId, RoutingPortSpec port) {
    if (port.isPassthrough) return analysis.arbiterTypes[nodeId];
    if (port.types.length == 1) return port.types.single;

    // A port that accepts several types takes the colour of what is connected to it, when that is a single type.
    final Set<RoutingPortType> connected = {
      for (final edge in graph.edges)
        if (edge.toNode == nodeId && edge.toPort == port.id) ?_outputType(edge.fromNode, edge.fromPort),
    };
    return connected.length == 1 ? connected.single : null;
  }

  RoutingPortType? _outputType(String nodeId, String portId) {
    final port = graph.nodes.firstWhereOrNull((node) => node.id == nodeId)?.data.port(portId);
    if (port == null) return null;
    return port.isPassthrough ? analysis.arbiterTypes[nodeId] : port.types.singleOrNull;
  }

  @override
  int noteRows(String nodeId) => notesOf(nodeId).length;

  List<Object?> _currentShapes() => [
    for (final node in graph.nodes) ...[
      node.id,
      noteRows(node.id),
      for (final port in node.data.ports) portType(node.id, port),
    ],
  ];

  // /////////////// //
  // Model to editor //
  // /////////////// //

  void addNode(RoutingNodeKind kind, Offset scenePosition) {
    assert(kind != RoutingNodeKind.source, 'A graph has exactly one source');
    editor.addNode(routingGraphNode(id: editor.nextId(kind.name), position: scenePosition, data: kind.defaultData));
  }

  void removeNode(String nodeId) => editor.removeNodes([nodeId]);

  void removeConnections(Iterable<String> connectionIds) => editor.removeConnections(connectionIds);

  void updateNodeData(String nodeId, RoutingNodeData data) {
    editor.updateNode(nodeId, (node) => node.withData({routingDataKey: data}));
  }

  // ////////////////// //
  // Printers and media //
  // ////////////////// //

  @observable
  bool isRefreshingPrinters = false;

  /// Lists the printers, queues and media again, e.g. after connecting a printer or starting the CUPS server.
  Future<void> refreshPrinters() async {
    if (isRefreshingPrinters) return;
    runInAction(() {
      isRefreshingPrinters = true;
      media.clear();
    });
    _requestedMedia.clear();
    try {
      await loadQueues();
      for (final node in graph.nodes) {
        if (node.data case PrinterNodeData(:final backend, :final queueId)) ensureMedia(backend, queueId);
      }
    } finally {
      runInAction(() => isRefreshingPrinters = false);
    }
  }

  Future<void> loadQueues() async {
    try {
      final canList = await hardware.canListNativeMedia();
      if (canList != canListNativeMedia && !_disposed) {
        runInAction(() => canListNativeMedia = canList);
        // The media field of native printers appears or disappears, which changes their height.
        editor.revalidate();
      }
    } catch (error, stackTrace) {
      logWarning('Could not check whether native printers list their media', error, stackTrace);
    }

    for (final backend in PrinterBackend.values) {
      try {
        final queues = ObservableList.of(await hardware.listQueues(backend));
        runInAction(() => switch (backend) {
          PrinterBackend.native => nativeQueues = queues,
          PrinterBackend.cups => cupsQueues = queues,
        });
      } catch (error, stackTrace) {
        logWarning('Could not list ${backend.name} print queues', error, stackTrace);
      }
    }
  }

  /// Loads the media of queue [queueId] into [media], once. Does nothing for native printers when they do not list
  /// their media. Safe to call while building.
  void ensureMedia(PrinterBackend backend, String queueId) {
    if (queueId.isEmpty || (backend == PrinterBackend.native && !canListNativeMedia)) return;
    if (!_requestedMedia.add((backend, queueId))) return;
    unawaited(_loadMedia(backend, queueId));
  }

  Future<void> _loadMedia(PrinterBackend backend, String queueId) async {
    try {
      final list = await hardware.listMedia(backend, queueId);
      runInAction(() => media[(backend, queueId)] = list);
    } catch (error, stackTrace) {
      logWarning('Could not list the media of ${backend.name} queue $queueId', error, stackTrace);
    }
  }

}
