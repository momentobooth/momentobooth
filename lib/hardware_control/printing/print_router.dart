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

  /// The stack node the copy passes, which puts it on a sheet together with the other copies of the print. Null when
  /// the copy is printed on a sheet of its own.
  final String? stackNodeId;
  final StackNodeData? stack;

  const PrintRoute({
    required this.printerNodeId,
    required this.printer,
    required this.margins,
    this.layout,
    this.stackNodeId,
    this.stack,
  });

  /// What the rendered sheet depends on besides the photo. Routes with the same key can share one rendering.
  Object get renderKey => (printer.media.widthMm, printer.media.heightMm, margins, layout);

  @override
  bool operator ==(Object other) =>
      other is PrintRoute &&
      other.printerNodeId == printerNodeId &&
      other.printer == printer &&
      other.margins == margins &&
      other.layout == layout &&
      other.stackNodeId == stackNodeId &&
      other.stack == stack;

  @override
  int get hashCode => Object.hash(printerNodeId, printer, margins, layout, stackNodeId, stack);

  @override
  String toString() => 'PrintRoute(${[printerNodeId, printer.label, margins, ?layout, ?stackNodeId].join(', ')})';

}

/// Sends one sheet of a print to a printer, or, for a route through a stack node, puts the copy on the stack. Returns
/// whether the printer took it.
typedef PrintSheet = Future<bool> Function(PrintRoute route);

/// Picks the printers for the copies of a print by following the routable edges of a [PrintRoutingGraph].
///
/// Round-robin nodes keep their position for as long as the router lives. Branches that do not lead to a usable printer
/// for the print size are skipped, so a job never ends up nowhere. When a printer fails, a round-robin node tries its
/// next output, and a duplicate node still prints on its other outputs.
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

  /// Prints the next copy of a print of [size] with [printSheet]: one sheet per printer the copy reaches, so several
  /// when its route passes a duplicate node. Returns whether at least one printer took a sheet; false as well when
  /// [size] is not routed to a printer.
  Future<bool> printCopy(PrintSize size, PrintSheet printSheet) async {
    final sourceId = analysis.sourceId;
    if (sourceId == null) return false;
    final starts = [
      for (final edge in _jobEdgesFrom[sourceId] ?? const <RoutingEdge>[])
        if (edge.fromPort == RoutingPorts.source(size)) edge,
    ];
    return _printOnAll(size, starts, null, printSheet);
  }

  Future<bool> _print(PrintSize size, String nodeId, TileLayoutNodeData? layout, PrintSheet printSheet, {String? stackNodeId}) async {
    if (!_reaches(size, nodeId)) return false;
    final candidates = [
      for (final edge in _jobEdgesFrom[nodeId] ?? const <RoutingEdge>[])
        if (_reaches(size, edge.toNode)) edge,
    ];

    switch (_nodes[nodeId]!.data) {
      case final PrinterNodeData printer:
        return printSheet(PrintRoute(
          printerNodeId: nodeId,
          printer: printer,
          margins: _marginsOf(nodeId, printer),
          layout: layout,
          stackNodeId: stackNodeId,
          stack: _nodes[stackNodeId]?.data as StackNodeData?,
        ));
      case final TileLayoutNodeData tile:
        // Split prints are always printed in halves.
        return _printOnAll(size, candidates, size == PrintSize.split ? layout : tile, printSheet);
      case StackNodeData():
        // Only connects to a printer.
        return _printOnAll(size, candidates, null, printSheet, stackNodeId: nodeId);
      case DuplicateNodeData():
        return _printOnAll(size, candidates, layout, printSheet);
      case RoundRobinNodeData():
        // Starting at its turn, the first output whose printers take the copy prints it. The next copy starts after it.
        final start = _roundRobinPositions[nodeId] ?? 0;
        for (int i = 0; i < candidates.length; i++) {
          final position = (start + i) % candidates.length;
          if (await _print(size, candidates[position].toNode, layout, printSheet)) {
            _roundRobinPositions[nodeId] = position + 1;
            return true;
          }
        }
        _roundRobinPositions[nodeId] = start + 1;
        return false;
      case SourceNodeData() || MarginsNodeData():
        return false;
    }
  }

  /// Prints on every one of [edges], also when an earlier one fails. Returns whether any printer took a sheet.
  Future<bool> _printOnAll(PrintSize size, List<RoutingEdge> edges, TileLayoutNodeData? layout, PrintSheet printSheet, {String? stackNodeId}) async {
    bool printed = false;
    for (final edge in edges) {
      if (await _print(size, edge.toNode, layout, printSheet, stackNodeId: stackNodeId)) printed = true;
    }
    return printed;
  }

  /// The route to the printer of stack [stackNodeId], or null when it has none: the stack does not exist (any more),
  /// or its printer is not usable. Used to print copies that waited on the stack.
  PrintRoute? stackRoute(String stackNodeId) {
    if (_nodes[stackNodeId]?.data case final StackNodeData stack) {
      final usablePrinters = {for (final printerIds in analysis.reachablePrinterIds.values) ...printerIds};
      for (final edge in _jobEdgesFrom[stackNodeId] ?? const <RoutingEdge>[]) {
        if (_nodes[edge.toNode]?.data case final PrinterNodeData printer when usablePrinters.contains(edge.toNode)) {
          return PrintRoute(
            printerNodeId: edge.toNode,
            printer: printer,
            margins: _marginsOf(edge.toNode, printer),
            stackNodeId: stackNodeId,
            stack: stack,
          );
        }
      }
    }
    return null;
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
      StackNodeData() => onlyValue(branches(null)),
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

  PrintMargins _marginsOf(String printerNodeId, PrinterNodeData printer) => switch (_nodes[_marginsNodeOf[printerNodeId]]?.data) {
    MarginsNodeData(:final margins) => margins,
    _ => printer.margins,
  };

}

/// The print sizes users can choose for a photo, given the [routed] print sizes. Split prints are not a choice: a
/// collage of three photos chosen at normal size is printed split when that is routed, so normal is offered for it even
/// when only split is routed.
List<PrintSize> choosablePrintSizes(Set<PrintSize> routed, {required bool isThreePhotoCollage}) => [
  if (routed.contains(PrintSize.normal) || (isThreePhotoCollage && routed.contains(PrintSize.split))) PrintSize.normal,
  for (final size in [PrintSize.small, PrintSize.tiny])
    if (routed.contains(size)) size,
];
