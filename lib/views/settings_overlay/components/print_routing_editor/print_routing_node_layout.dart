import 'dart:math' as math;

import 'package:fl_nodes_v2/fl_nodes_v2.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:momento_booth/models/print_routing_graph.dart';
import 'package:momento_booth/models/settings.dart';

/// Key under which a [GraphNode] stores its [RoutingNodeData].
///
/// The Freezed object is stored as is: the library compares `data` values with `==`, which Freezed implements, and
/// the library's own codec is not used, so the value never needs to be JSON.
const String routingDataKey = 'routing';

/// The node types of the print routing graph, with what the editor needs to know about each.
enum RoutingNodeKind {

  source('Source', 180, RoutingNodeData.source()),
  roundRobin('Round-robin', 200, RoutingNodeData.roundRobin()),
  duplicate('Duplicate', 200, RoutingNodeData.duplicate()),
  tileLayout('Tile layout', 240, RoutingNodeData.tileLayout()),
  stack('Stack', 240, RoutingNodeData.stack()),
  margins('Margins', 260, RoutingNodeData.margins()),
  printer('Printer', 340, RoutingNodeData.printer());

  final String label;
  final double width;
  final RoutingNodeData defaultData;

  const RoutingNodeKind(this.label, this.width, this.defaultData);

  IconData get icon => switch (this) {
    source => LucideIcons.images,
    roundRobin => LucideIcons.repeat,
    duplicate => LucideIcons.copy,
    tileLayout => LucideIcons.layoutGrid,
    stack => LucideIcons.rows3,
    margins => LucideIcons.squareDashed,
    printer => LucideIcons.printer,
  };

  /// Tints the node header and the button that adds the node.
  AccentColor get color => switch (this) {
    source => Colors.blue,
    roundRobin => Colors.purple,
    duplicate => Colors.magenta,
    tileLayout => Colors.orange,
    stack => Colors.yellow,
    margins => Colors.green,
    printer => Colors.teal,
  };

  /// The shade the header tint and the button that adds the node are derived from. The normal shade of yellow is so
  /// light that it hardly shows as a tint.
  Color get tintBase => this == stack ? color.darker : color.normal;

  static RoutingNodeKind of(RoutingNodeData data) => switch (data) {
    SourceNodeData() => source,
    RoundRobinNodeData() => roundRobin,
    DuplicateNodeData() => duplicate,
    TileLayoutNodeData() => tileLayout,
    StackNodeData() => stack,
    MarginsNodeData() => margins,
    PrinterNodeData() => printer,
  };

}

Color routingNodeKindTint(RoutingNodeKind kind) => kind.tintBase.withValues(alpha: 0.14);

String printSizeShortLabel(PrintSize size) => switch (size) {
  PrintSize.normal => 'Normal',
  PrintSize.split => 'Split',
  PrintSize.small => 'Small',
  PrintSize.tiny => 'Tiny',
};

String routingPortLabel(RoutingNodeData data, RoutingPortSpec port) => switch (data) {
  SourceNodeData() => printSizeShortLabel(PrintSize.values.byName(port.id)),
  RoundRobinNodeData() || DuplicateNodeData() => port.direction == RoutingPortDirection.input ? 'In' : 'Out',
  TileLayoutNodeData() => port.direction == RoutingPortDirection.input ? 'Photo' : 'Sheet',
  StackNodeData() => port.direction == RoutingPortDirection.input ? 'Photo' : 'Stack',
  MarginsNodeData() => 'Margins',
  PrinterNodeData() => port.id == RoutingPorts.margins ? 'Margins' : 'Job',
};

/// Colours that tell the port types apart. Null for a port that does not carry a single known type.
Color? routingPortTypeColor(RoutingPortType? type) => switch (type) {
  RoutingPortType.photo => Colors.blue.normal,
  RoutingPortType.sheet => Colors.orange.normal,
  // The normal shade of yellow is too bright on a light canvas.
  RoutingPortType.stack => Colors.yellow.darker,
  RoutingPortType.margins => Colors.green.normal,
  null => null,
};

/// Fixed row heights of the node cards.
abstract final class RoutingNodeMetrics {

  static const double headerHeight = 36;
  static const double portRowHeight = 26;
  static const double fieldRowHeight = 44;
  static const double captionRowHeight = 26;
  static const double noteRowHeight = 22;
  static const double bottomPadding = 8;

}

/// The rows of a node card: header, port rows, fields, a caption, the margin fields of a printer and the notes.
///
/// Port anchors are fractions of the node height, so the card and its port positions are both derived from this.
class RoutingNodeLayout {

  final RoutingNodeData data;

  /// Whether the margins input of a printer is connected, which hides its inline margin fields.
  final bool marginsWired;
  final int noteRows;

  /// Whether native printers list their media, which a printer then chooses from like a CUPS queue.
  final bool canListNativeMedia;

  const RoutingNodeLayout(this.data, {required this.marginsWired, required this.noteRows, required this.canListNativeMedia});

  /// The ports drawn in the rows below the header: inputs on the left, outputs on the right. The margins input of a
  /// printer is drawn at its margins section instead.
  List<RoutingPortSpec> rowPorts(RoutingPortDirection direction) => [
    for (final port in data.ports)
      if (port.direction == direction && !_isPrinterMargins(port)) port,
  ];

  int get portRows => math.max(rowPorts(RoutingPortDirection.input).length, rowPorts(RoutingPortDirection.output).length);

  int get fieldRows => switch (data) {
    SourceNodeData() || RoundRobinNodeData() || DuplicateNodeData() || MarginsNodeData() => 0,
    TileLayoutNodeData() || StackNodeData() => 2,
    // Label, backend, queue, (media,) size.
    PrinterNodeData(:final backend) => backend == PrinterBackend.cups || canListNativeMedia ? 5 : 4,
  };

  /// A caption row tells what an arbiter carries, or heads a margins section.
  bool get hasCaptionRow => switch (data) {
    RoundRobinNodeData() || DuplicateNodeData() || PrinterNodeData() || MarginsNodeData() => true,
    SourceNodeData() || TileLayoutNodeData() || StackNodeData() => false,
  };

  int get marginFieldRows => switch (data) {
    MarginsNodeData() => 2,
    PrinterNodeData() when !marginsWired => 2,
    _ => 0,
  };

  double get _captionTop =>
      RoutingNodeMetrics.headerHeight + portRows * RoutingNodeMetrics.portRowHeight + fieldRows * RoutingNodeMetrics.fieldRowHeight;

  double get height =>
      _captionTop +
      (hasCaptionRow ? RoutingNodeMetrics.captionRowHeight : 0) +
      marginFieldRows * RoutingNodeMetrics.fieldRowHeight +
      noteRows * RoutingNodeMetrics.noteRowHeight +
      RoutingNodeMetrics.bottomPadding;

  /// Vertical centre of [port], in node-local pixels.
  double portCenter(RoutingPortSpec port) {
    if (_isPrinterMargins(port)) return _captionTop + RoutingNodeMetrics.captionRowHeight / 2;
    final row = rowPorts(port.direction).indexWhere((rowPort) => rowPort.id == port.id);
    return RoutingNodeMetrics.headerHeight + row * RoutingNodeMetrics.portRowHeight + RoutingNodeMetrics.portRowHeight / 2;
  }

  bool _isPrinterMargins(RoutingPortSpec port) => data is PrinterNodeData && port.id == RoutingPorts.margins;

}

/// Derived state that shapes and colours nodes, beyond their own data.
abstract interface class RoutingNodeShapeSource {

  /// The type [port] of node [nodeId] carries, or null when that is not a single known type.
  RoutingPortType? portType(String nodeId, RoutingPortSpec port);

  int noteRows(String nodeId);

  bool get canListNativeMedia;

}

/// One definition per node type. Ports and height are derived from the [RoutingNodeData], the wiring and [shapes] on
/// every resolution pass, so they never need to be stored or mapped by hand.
NodeDefinitionRegistry routingNodeDefinitions(RoutingNodeShapeSource shapes) => NodeDefinitionRegistry([
  for (final kind in RoutingNodeKind.values)
    NodeDefinition(
      type: kind.name,
      defaultWidth: kind.width,
      ports: [DynamicPortFamily(id: 'ports', build: (context) => _buildPorts(context, shapes))],
      resolveHeight: (context) => _layoutOf(context, shapes)?.height,
      // A graph has exactly one source: the editor's delete, copy, cut, duplicate and paste leave it alone.
      deletable: kind != RoutingNodeKind.source,
      copyable: kind != RoutingNodeKind.source,
    ),
]);

RoutingNodeLayout? _layoutOf(NodeResolutionContext context, RoutingNodeShapeSource shapes) {
  final data = context.field<RoutingNodeData>(routingDataKey);
  if (data == null) return null;
  return RoutingNodeLayout(
    data,
    marginsWired: data is PrinterNodeData && context.isConnected(RoutingPorts.margins),
    noteRows: shapes.noteRows(context.nodeId),
    canListNativeMedia: shapes.canListNativeMedia,
  );
}

List<NodePort> _buildPorts(NodeResolutionContext context, RoutingNodeShapeSource shapes) {
  final layout = _layoutOf(context, shapes);
  if (layout == null) return const [];

  return [
    for (final spec in layout.data.ports)
      NodePort(
        id: spec.id,
        direction: spec.direction == RoutingPortDirection.input ? PortDirection.input : PortDirection.output,
        label: routingPortLabel(layout.data, spec),
        anchor: Offset(spec.direction == RoutingPortDirection.input ? 0 : 1, layout.portCenter(spec) / layout.height),
        color: routingPortTypeColor(shapes.portType(context.nodeId, spec)),
        // A single type is checked by the library itself. Ports that accept several types, and passthrough ports, are
        // wildcards here and checked by PrintRoutingAnalysis.checkConnection in the connection validator. Connection
        // limits are left to the editor too, which replaces a connection instead of refusing a full port.
        dataType: !spec.isPassthrough && spec.types.length == 1 ? spec.types.single.name : null,
      ),
  ];
}

GraphNode routingGraphNode({required String id, required Offset position, required RoutingNodeData data}) {
  final kind = RoutingNodeKind.of(data);
  return GraphNode(id: id, type: kind.name, position: position, width: kind.width, data: {routingDataKey: data});
}

/// Converts our model to the library's. Ports are left empty; the definitions fill them in on resolution.
///
/// Lossy for invalid input: duplicate node IDs collapse into one node, and resolution drops edges that reference a
/// port that does not exist.
NodeGraph toNodeGraph(PrintRoutingGraph graph) => NodeGraph(
  nodes: [
    for (final node in graph.nodes) routingGraphNode(id: node.id, position: Offset(node.x, node.y), data: node.data),
  ],
  connections: [
    for (final (index, edge) in graph.edges.indexed)
      NodeConnection(
        id: 'edge_$index',
        from: PortRef(edge.fromNode, edge.fromPort),
        to: PortRef(edge.toNode, edge.toPort),
      ),
  ],
);

/// Converts the library's graph back to our model, in the library's node and connection order.
PrintRoutingGraph toPrintRoutingGraph(NodeGraph graph) => PrintRoutingGraph(
  nodes: [
    for (final node in graph.nodes.values)
      if (node.field<RoutingNodeData>(routingDataKey) case final RoutingNodeData data)
        RoutingNode(id: node.id, x: node.position.dx, y: node.position.dy, data: data),
  ],
  edges: [
    for (final connection in graph.connections.values)
      RoutingEdge(
        fromNode: connection.from.nodeId,
        fromPort: connection.from.portId,
        toNode: connection.to.nodeId,
        toPort: connection.to.portId,
      ),
  ],
);
