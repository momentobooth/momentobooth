import 'package:flutter/foundation.dart';
import 'package:momento_booth/hardware_control/printing/print_routing_analysis.dart';
import 'package:momento_booth/models/print_routing_graph.dart';
import 'package:momento_booth/models/settings.dart';

/// Where one sheet of a print is printed, and how the photo is laid out on it.
@immutable
class PrintRoute {

  final String printerNodeId;
  final PrinterNodeData printer;
  final PrintMargins margins;

  /// Null when the photo is fitted on the sheet as a whole.
  final TileLayoutNodeData? layout;

  const PrintRoute({required this.printerNodeId, required this.printer, required this.margins, this.layout});

  /// What the rendered sheet depends on besides the photo. Routes with the same key can share one rendering.
  Object get renderKey => (printer.media.widthMm, printer.media.heightMm, margins, layout);

  @override
  bool operator ==(Object other) =>
      other is PrintRoute &&
      other.printerNodeId == printerNodeId &&
      other.printer == printer &&
      other.margins == margins &&
      other.layout == layout;

  @override
  int get hashCode => Object.hash(printerNodeId, printer, margins, layout);

  @override
  String toString() => 'PrintRoute($printerNodeId, ${printer.label}, $margins, $layout)';

}

/// Picks the printers for the copies of a print by following the routable edges of a [PrintRoutingGraph].
///
/// Round-robin nodes keep their position for as long as the router lives. Branches that do not lead to a usable printer
/// for the print size are skipped, so a job never ends up nowhere.
class PrintRouter {

  final PrintRoutingGraph graph;
  final PrintRoutingAnalysis analysis;

  final Map<String, RoutingNode> _nodes = {};
  final Map<String, List<RoutingEdge>> _jobEdgesFrom = {};
  final Map<String, String> _marginsNodeOf = {};
  final Map<String, int> _roundRobinPositions = {};
  final Map<(PrintSize, String), bool> _reachesPrinter = {};

  PrintRouter(this.graph) : analysis = PrintRoutingAnalysis.of(graph) {
    for (final node in graph.nodes) {
      // The analysis ignores later nodes with the same ID too.
      _nodes.putIfAbsent(node.id, () => node);
    }
    for (final edge in analysis.routableEdges) {
      if (_nodes[edge.toNode]!.data.port(edge.toPort)!.types.any(jobPortTypes.contains)) {
        (_jobEdgesFrom[edge.fromNode] ??= []).add(edge);
      } else if (edge.toPort == RoutingPorts.margins) {
        _marginsNodeOf[edge.toNode] = edge.fromNode;
      }
    }
  }

  Set<PrintSize> get printableSizes => {
    for (final size in PrintSize.values)
      if (analysis.reachablePrinterIds[size]!.isNotEmpty) size,
  };

  /// The printer nodes any print size can end up at.
  Iterable<PrinterNodeData> get usedPrinters => {
    for (final printerIds in analysis.reachablePrinterIds.values) ...printerIds,
  }.map((id) => _nodes[id]!.data as PrinterNodeData);

  /// The sheets to print for the next copy of a print of [size]: one per printer the copy reaches, so several when its
  /// route passes a duplicate node. Empty when [size] is not routed to a printer.
  List<PrintRoute> nextCopy(PrintSize size) {
    final sourceId = analysis.sourceId;
    if (sourceId == null) return const [];
    return [
      for (final edge in _jobEdgesFrom[sourceId] ?? const <RoutingEdge>[])
        if (edge.fromPort == RoutingPorts.source(size)) ..._follow(size, edge.toNode, null),
    ];
  }

  List<PrintRoute> _follow(PrintSize size, String nodeId, TileLayoutNodeData? layout) {
    if (!_reaches(size, nodeId)) return const [];
    final candidates = [
      for (final edge in _jobEdgesFrom[nodeId] ?? const <RoutingEdge>[])
        if (_reaches(size, edge.toNode)) edge,
    ];

    return switch (_nodes[nodeId]!.data) {
      final PrinterNodeData printer => [
        PrintRoute(printerNodeId: nodeId, printer: printer, margins: _marginsOf(nodeId, printer), layout: layout),
      ],
      // Split prints are always printed in halves.
      final TileLayoutNodeData tile => [
        for (final edge in candidates) ..._follow(size, edge.toNode, size == PrintSize.split ? layout : tile),
      ],
      RoundRobinNodeData() => _follow(size, candidates[_nextPosition(nodeId, candidates.length)].toNode, layout),
      DuplicateNodeData() => [
        for (final edge in candidates) ..._follow(size, edge.toNode, layout),
      ],
      SourceNodeData() || MarginsNodeData() => const [],
    };
  }

  /// How many times one copy of [size] puts the photo on paper: once per tile, and once for a split print, in two
  /// halves. Null when that depends on the printer it ends up at, or when [size] is not routed.
  int? photosPerCopy(PrintSize size) {
    final starts = {
      for (final edge in _jobEdgesFrom[analysis.sourceId] ?? const <RoutingEdge>[])
        if (edge.fromPort == RoutingPorts.source(size) && _reaches(size, edge.toNode)) _photosFrom(size, edge.toNode, null),
    };
    return starts.length == 1 ? starts.single : null;
  }

  int? _photosFrom(PrintSize size, String nodeId, TileLayoutNodeData? layout) {
    Iterable<int?> branches(TileLayoutNodeData? layout) => [
      for (final edge in _jobEdgesFrom[nodeId] ?? const <RoutingEdge>[])
        if (_reaches(size, edge.toNode)) _photosFrom(size, edge.toNode, layout),
    ];
    int? onlyValue(Iterable<int?> values) => values.toSet().length == 1 ? values.first : null;

    return switch (_nodes[nodeId]!.data) {
      PrinterNodeData() => layout == null ? 1 : layout.columns * layout.rows,
      final TileLayoutNodeData tile => onlyValue(branches(size == PrintSize.split ? layout : tile)),
      RoundRobinNodeData() => onlyValue(branches(layout)),
      DuplicateNodeData() => branches(layout).fold<int?>(0, (sum, photos) => sum == null || photos == null ? null : sum + photos),
      SourceNodeData() || MarginsNodeData() => null,
    };
  }

  /// Whether [nodeId] leads to a usable printer for [size]. The routable edges never loop, so this terminates.
  bool _reaches(PrintSize size, String nodeId) => _reachesPrinter[(size, nodeId)] ??= switch (_nodes[nodeId]?.data) {
    PrinterNodeData() => analysis.reachablePrinterIds[size]!.contains(nodeId),
    null => false,
    _ => (_jobEdgesFrom[nodeId] ?? const <RoutingEdge>[]).any((edge) => _reaches(size, edge.toNode)),
  };

  int _nextPosition(String nodeId, int count) {
    final position = _roundRobinPositions[nodeId] ?? 0;
    _roundRobinPositions[nodeId] = position + 1;
    return position % count;
  }

  PrintMargins _marginsOf(String printerNodeId, PrinterNodeData printer) => switch (_nodes[_marginsNodeOf[printerNodeId]]?.data) {
    MarginsNodeData(:final margins) => margins,
    _ => printer.margins,
  };

}
