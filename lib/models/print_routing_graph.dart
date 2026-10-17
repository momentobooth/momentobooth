// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:momento_booth/models/settings.dart';
import 'package:toml/toml.dart';

part 'print_routing_graph.freezed.dart';
part 'print_routing_graph.g.dart';

// ///// //
// Graph //
// ///// //

/// A user-defined graph that routes print jobs from the print sizes MomentoBooth offers to printer configurations.
///
/// This is the persisted source of truth. Node editor libraries only present and edit it.
@Freezed(fromJson: true, toJson: true)
sealed class PrintRoutingGraph with _$PrintRoutingGraph implements TomlEncodableValue {

  const PrintRoutingGraph._();

  const factory PrintRoutingGraph({
    @Default([]) List<RoutingNode> nodes,
    @Default([]) List<RoutingEdge> edges,
  }) = _PrintRoutingGraph;

  /// Routes normal prints to a single printer, which still has to be configured.
  factory PrintRoutingGraph.withDefaults() => const PrintRoutingGraph(
    nodes: [
      RoutingNode(id: 'source', data: RoutingNodeData.source()),
      RoutingNode(id: 'printer', x: 260, data: RoutingNodeData.printer()),
    ],
    edges: [
      RoutingEdge(fromNode: 'source', fromPort: 'normal', toNode: 'printer', toPort: RoutingPorts.input),
    ],
  );

  /// Adds a source node when the stored graph has none, see [withSource].
  factory PrintRoutingGraph.fromJson(Map<String, Object?> json) => _$PrintRoutingGraphFromJson(json).withSource();

  @override
  Map<String, dynamic> toTomlValue() => toJson();

  /// Returns this graph with a source node added if it has none. A graph has exactly one source.
  PrintRoutingGraph withSource() {
    if (nodes.any((node) => node.data is SourceNodeData)) return this;

    final Set<String> ids = {for (final node in nodes) node.id};
    String id = 'source';
    for (int i = 1; ids.contains(id); i++) {
      id = 'source_$i';
    }
    return copyWith(nodes: [RoutingNode(id: id, data: const RoutingNodeData.source()), ...nodes]);
  }

  /// Returns this graph with [edge] added. Where that exceeds the maximum number of connections of a port, the oldest connections of that port are replaced.
  PrintRoutingGraph withEdge(RoutingEdge edge) {
    final Set<RoutingEdge> replaced = {};

    void makeRoom(String nodeId, String portId, RoutingPortDirection direction, bool Function(RoutingEdge existing) isOnPort) {
      final port = nodes.where((node) => node.id == nodeId).firstOrNull?.data.port(portId);
      final maxConnections = port?.maxConnections;
      if (port == null || port.direction != direction || maxConnections == null) return;

      final connected = edges.where(isOnPort).toList();
      if (connected.length >= maxConnections) replaced.addAll(connected.take(connected.length - maxConnections + 1));
    }

    makeRoom(edge.fromNode, edge.fromPort, RoutingPortDirection.output, (existing) => existing.fromNode == edge.fromNode && existing.fromPort == edge.fromPort);
    makeRoom(edge.toNode, edge.toPort, RoutingPortDirection.input, (existing) => existing.toNode == edge.toNode && existing.toPort == edge.toPort);
    return copyWith(edges: [...edges.where((existing) => !replaced.contains(existing)), edge]);
  }

}

@Freezed(fromJson: true, toJson: true)
sealed class RoutingNode with _$RoutingNode {

  const factory RoutingNode({
    required String id,

    /// Position of the node in the editor canvas, stored in whole pixels.
    @JsonKey(toJson: _roundPosition) @Default(0.0) double x,
    @JsonKey(toJson: _roundPosition) @Default(0.0) double y,

    required RoutingNodeData data,
  }) = _RoutingNode;

  factory RoutingNode.fromJson(Map<String, Object?> json) => _$RoutingNodeFromJson(json);

}

double _roundPosition(double position) => position.roundToDouble();

/// A connection from an output port to an input port.
@Freezed(fromJson: true, toJson: true)
sealed class RoutingEdge with _$RoutingEdge {

  const factory RoutingEdge({
    required String fromNode,
    required String fromPort,
    required String toNode,
    required String toPort,
  }) = _RoutingEdge;

  factory RoutingEdge.fromJson(Map<String, Object?> json) => _$RoutingEdgeFromJson(json);

}

// ////////// //
// Node types //
// ////////// //

@Freezed(unionKey: 'type', fromJson: true, toJson: true)
sealed class RoutingNodeData with _$RoutingNodeData {

  const RoutingNodeData._();

  /// Emits a photo for each print size the user can choose.
  const factory RoutingNodeData.source() = SourceNodeData;

  /// Distributes jobs (each copy separately) over all connected outputs in turn.
  const factory RoutingNodeData.roundRobin() = RoundRobinNodeData;

  /// Sends every job to all connected outputs, e.g. to print a photo both as a normal and as a tiled print.
  const factory RoutingNodeData.duplicate() = DuplicateNodeData;

  /// Tiles a photo in a grid on the sheet of the printer it ends up at.
  const factory RoutingNodeData.tileLayout({
    @Default(1) int columns,
    @Default(1) int rows,
    @Default(false) bool rotate,
  }) = TileLayoutNodeData;

  /// Margins that can be shared between printer configurations.
  const factory RoutingNodeData.margins({
    @Default(PrintMargins()) PrintMargins margins,
  }) = MarginsNodeData;

  /// A printer configuration: one printer or queue with one media size.
  const factory RoutingNodeData.printer({
    /// Name to tell configurations apart, e.g. when several use the same queue.
    @Default('') String label,
    @Default(PrinterBackend.native) PrinterBackend backend,

    /// Printer name for [PrinterBackend.native], queue ID for [PrinterBackend.cups].
    @Default('') String queueId,
    @Default(PrintMedia()) PrintMedia media,

    /// Used when no margins node is connected.
    @Default(PrintMargins()) PrintMargins margins,
  }) = PrinterNodeData;

  factory RoutingNodeData.fromJson(Map<String, Object?> json) => _$RoutingNodeDataFromJson(json);

  // Only arbiters split the job flow, so jobs never fan out implicitly: other job outputs take a single connection.
  List<RoutingPortSpec> get ports => switch (this) {
    SourceNodeData() => [
      for (final size in PrintSize.values)
        RoutingPortSpec(
          id: RoutingPorts.source(size),
          direction: RoutingPortDirection.output,
          types: const {RoutingPortType.photo},
          maxConnections: 1,
        ),
    ],
    RoundRobinNodeData() || DuplicateNodeData() => const [
      RoutingPortSpec(id: RoutingPorts.input, direction: RoutingPortDirection.input, types: jobPortTypes, isPassthrough: true),
      RoutingPortSpec(id: RoutingPorts.output, direction: RoutingPortDirection.output, types: jobPortTypes, isPassthrough: true),
    ],
    TileLayoutNodeData() => const [
      RoutingPortSpec(id: RoutingPorts.input, direction: RoutingPortDirection.input, types: {RoutingPortType.photo}, maxConnections: 1),
      RoutingPortSpec(id: RoutingPorts.output, direction: RoutingPortDirection.output, types: {RoutingPortType.sheet}, maxConnections: 1),
    ],
    MarginsNodeData() => const [
      RoutingPortSpec(id: RoutingPorts.margins, direction: RoutingPortDirection.output, types: {RoutingPortType.margins}),
    ],
    PrinterNodeData() => const [
      // A photo connected directly is fitted on the sheet as a single tile.
      RoutingPortSpec(id: RoutingPorts.input, direction: RoutingPortDirection.input, types: jobPortTypes),
      RoutingPortSpec(id: RoutingPorts.margins, direction: RoutingPortDirection.input, types: {RoutingPortType.margins}, maxConnections: 1),
    ],
  };

  RoutingPortSpec? port(String id) => ports.where((port) => port.id == id).firstOrNull;

}

enum PrinterBackend { native, cups }

@Freezed(fromJson: true, toJson: true)
sealed class PrintMedia with _$PrintMedia {

  const factory PrintMedia({
    /// CUPS media keyword, e.g. `custom_100x148mm`. Empty for [PrinterBackend.native].
    @Default('') String name,
    @Default(0.0) double widthMm,
    @Default(0.0) double heightMm,
  }) = _PrintMedia;

  factory PrintMedia.fromJson(Map<String, Object?> json) => _$PrintMediaFromJson(json);

}

/// Margins in mm that describe the area of the media that ends up visible on the print.
@Freezed(fromJson: true, toJson: true)
sealed class PrintMargins with _$PrintMargins {

  const factory PrintMargins({
    @Default(0.0) double top,
    @Default(0.0) double right,
    @Default(0.0) double bottom,
    @Default(0.0) double left,
  }) = _PrintMargins;

  factory PrintMargins.fromJson(Map<String, Object?> json) => _$PrintMarginsFromJson(json);

}

// ///// //
// Ports //
// ///// //

enum RoutingPortDirection { input, output }

enum RoutingPortType {

  /// A photo at the print size the user chose.
  photo,

  /// A photo laid out on a sheet.
  sheet,

  margins,

}

/// Types that carry print jobs, as opposed to values like margins.
const Set<RoutingPortType> jobPortTypes = {RoutingPortType.photo, RoutingPortType.sheet};

class RoutingPortSpec {

  final String id;
  final RoutingPortDirection direction;

  /// The types this port accepts.
  final Set<RoutingPortType> types;

  /// Whether this port carries the type of the jobs flowing into its node, which must be one of [types].
  final bool isPassthrough;

  /// Maximum number of connections, or null for no limit.
  final int? maxConnections;

  const RoutingPortSpec({
    required this.id,
    required this.direction,
    required this.types,
    this.isPassthrough = false,
    this.maxConnections,
  });

}

abstract final class RoutingPorts {

  static const String input = 'in';
  static const String output = 'out';
  static const String margins = 'margins';

  static String source(PrintSize size) => size.name;

}
