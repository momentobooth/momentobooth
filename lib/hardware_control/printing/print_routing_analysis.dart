import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:momento_booth/models/print_routing_graph.dart';
import 'package:momento_booth/models/settings.dart';

enum RoutingIssueSeverity { error, warning }

enum RoutingIssueKind {

  duplicateNodeId(RoutingIssueSeverity.error),
  missingSource(RoutingIssueSeverity.error),

  /// A source node besides the first one. It does not route anything.
  duplicateSource(RoutingIssueSeverity.error),
  invalidParameter(RoutingIssueSeverity.error),
  unknownNode(RoutingIssueSeverity.error),
  unknownPort(RoutingIssueSeverity.error),
  wrongDirection(RoutingIssueSeverity.error),
  duplicateEdge(RoutingIssueSeverity.error),
  tooManyConnections(RoutingIssueSeverity.error),
  incompatibleTypes(RoutingIssueSeverity.error),
  cycle(RoutingIssueSeverity.error),

  /// A printer that receives jobs, but has no queue or media size set.
  incompletePrinter(RoutingIssueSeverity.warning),

  /// A print size that does not reach any printer, so it cannot be printed.
  unroutedPrintSize(RoutingIssueSeverity.warning);

  final RoutingIssueSeverity severity;

  const RoutingIssueKind(this.severity);

}

@immutable
class RoutingIssue {

  final RoutingIssueKind kind;
  final String? nodeId;
  final RoutingEdge? edge;
  final PrintSize? printSize;

  const RoutingIssue({required this.kind, this.nodeId, this.edge, this.printSize});

  RoutingIssueSeverity get severity => kind.severity;

  @override
  bool operator ==(Object other) =>
      other is RoutingIssue && other.kind == kind && other.nodeId == nodeId && other.edge == edge && other.printSize == printSize;

  @override
  int get hashCode => Object.hash(kind, nodeId, edge, printSize);

  @override
  String toString() => 'RoutingIssue(${[kind.name, ?nodeId, ?edge, ?printSize?.name].join(', ')})';

}

/// The result of checking a [PrintRoutingGraph].
///
/// Nodes that are not connected to anything are fine; they can be kept around for later use.
class PrintRoutingAnalysis {

  final List<RoutingIssue> issues;

  /// IDs of the complete printer nodes each print size can end up at.
  final Map<PrintSize, Set<String>> reachablePrinterIds;

  /// The job type flowing through each arbiter node. Arbiters without incoming jobs are absent.
  final Map<String, RoutingPortType> arbiterTypes;

  const PrintRoutingAnalysis._(this.issues, this.reachablePrinterIds, this.arbiterTypes);

  bool get hasErrors => issues.any((issue) => issue.severity == RoutingIssueSeverity.error);

  Iterable<RoutingIssue> get errors => issues.where((issue) => issue.severity == RoutingIssueSeverity.error);

  factory PrintRoutingAnalysis.of(PrintRoutingGraph graph) => _Analyzer(graph).run();

  /// Checks whether [edge] can be added to [graph] with [PrintRoutingGraph.withEdge] without introducing errors.
  /// Returns the first new error, or null if the connection is allowed.
  static RoutingIssue? checkConnection(PrintRoutingGraph graph, RoutingEdge edge) {
    final currentErrors = PrintRoutingAnalysis.of(graph).errors.toSet();
    return PrintRoutingAnalysis.of(graph.withEdge(edge)).errors.firstWhereOrNull((issue) => !currentErrors.contains(issue));
  }

}

class _Analyzer {

  final PrintRoutingGraph graph;
  final List<RoutingIssue> issues = [];
  final Map<String, RoutingNode> nodes = {};
  String? sourceId;

  _Analyzer(this.graph);

  PrintRoutingAnalysis run() {
    _collectNodes();
    final edges = _validEdges();
    final acyclicEdges = _withoutCycles(edges);
    final arbiterTypes = _resolveTypes(acyclicEdges);
    final reachable = _reachablePrinters(edges);
    return PrintRoutingAnalysis._(issues, reachable, arbiterTypes);
  }

  void _collectNodes() {
    for (final node in graph.nodes) {
      if (nodes.containsKey(node.id)) {
        issues.add(RoutingIssue(kind: RoutingIssueKind.duplicateNodeId, nodeId: node.id));
        continue;
      }
      nodes[node.id] = node;

      if (node.data is SourceNodeData) {
        if (sourceId == null) {
          sourceId = node.id;
        } else {
          issues.add(RoutingIssue(kind: RoutingIssueKind.duplicateSource, nodeId: node.id));
        }
      }

      final bool validParameters = switch (node.data) {
        TileLayoutNodeData(:final columns, :final rows) => columns >= 1 && rows >= 1,
        _ => true,
      };
      if (!validParameters) issues.add(RoutingIssue(kind: RoutingIssueKind.invalidParameter, nodeId: node.id));
    }

    if (sourceId == null) issues.add(const RoutingIssue(kind: RoutingIssueKind.missingSource));
  }

  /// Returns the edges that connect existing ports in the right direction, within the connection limits.
  List<RoutingEdge> _validEdges() {
    final List<RoutingEdge> valid = [];
    final Map<(String, String), int> connectionCounts = {};

    for (final edge in graph.edges) {
      final from = nodes[edge.fromNode], to = nodes[edge.toNode];
      if (from == null || to == null) {
        issues.add(RoutingIssue(kind: RoutingIssueKind.unknownNode, edge: edge));
        continue;
      }

      final fromPort = from.data.port(edge.fromPort), toPort = to.data.port(edge.toPort);
      if (fromPort == null || toPort == null) {
        issues.add(RoutingIssue(kind: RoutingIssueKind.unknownPort, edge: edge));
        continue;
      }
      if (fromPort.direction != RoutingPortDirection.output || toPort.direction != RoutingPortDirection.input) {
        issues.add(RoutingIssue(kind: RoutingIssueKind.wrongDirection, edge: edge));
        continue;
      }
      if (valid.contains(edge)) {
        issues.add(RoutingIssue(kind: RoutingIssueKind.duplicateEdge, edge: edge));
        continue;
      }

      final fromCount = connectionCounts[(edge.fromNode, edge.fromPort)] ?? 0;
      final toCount = connectionCounts[(edge.toNode, edge.toPort)] ?? 0;
      if (_isFull(fromPort, fromCount) || _isFull(toPort, toCount)) {
        issues.add(RoutingIssue(kind: RoutingIssueKind.tooManyConnections, edge: edge));
        continue;
      }
      connectionCounts[(edge.fromNode, edge.fromPort)] = fromCount + 1;
      connectionCounts[(edge.toNode, edge.toPort)] = toCount + 1;

      valid.add(edge);
    }

    return valid;
  }

  /// Reports every edge that closes a cycle and returns the remaining edges.
  List<RoutingEdge> _withoutCycles(List<RoutingEdge> edges) {
    final outgoing = edges.groupListsBy((edge) => edge.fromNode);
    final Set<String> visiting = {}, done = {};
    final Set<RoutingEdge> backEdges = {};

    void visit(String nodeId) {
      visiting.add(nodeId);
      for (final edge in outgoing[nodeId] ?? const <RoutingEdge>[]) {
        if (visiting.contains(edge.toNode)) {
          backEdges.add(edge);
        } else if (!done.contains(edge.toNode)) {
          visit(edge.toNode);
        }
      }
      visiting.remove(nodeId);
      done.add(nodeId);
    }

    for (final nodeId in nodes.keys) {
      if (!done.contains(nodeId)) visit(nodeId);
    }

    for (final edge in edges.where(backEdges.contains)) {
      issues.add(RoutingIssue(kind: RoutingIssueKind.cycle, edge: edge));
    }
    return edges.whereNot(backEdges.contains).toList();
  }

  /// Checks the port types of all edges. Arbiters take the type of their first incoming job, so this follows the job flow.
  Map<String, RoutingPortType> _resolveTypes(List<RoutingEdge> acyclicEdges) {
    final Map<String, RoutingPortType> arbiterTypes = {};
    final incoming = acyclicEdges.groupListsBy((edge) => edge.toNode);

    for (final nodeId in _topologicalOrder(acyclicEdges)) {
      final node = nodes[nodeId]!;
      for (final edge in incoming[nodeId] ?? const <RoutingEdge>[]) {
        final fromPort = nodes[edge.fromNode]!.data.port(edge.fromPort)!;
        final toPort = node.data.port(edge.toPort)!;

        // Unresolved when it comes from an arbiter without incoming jobs, which does not constrain anything yet.
        final RoutingPortType? type = fromPort.isPassthrough ? arbiterTypes[edge.fromNode] : fromPort.types.single;
        if (type == null) continue;

        if (!toPort.types.contains(type) || (toPort.isPassthrough && (arbiterTypes[nodeId] ?? type) != type)) {
          issues.add(RoutingIssue(kind: RoutingIssueKind.incompatibleTypes, edge: edge));
        } else if (toPort.isPassthrough) {
          arbiterTypes[nodeId] = type;
        }
      }
    }

    return arbiterTypes;
  }

  List<String> _topologicalOrder(List<RoutingEdge> acyclicEdges) {
    final outgoing = acyclicEdges.groupListsBy((edge) => edge.fromNode);
    final Map<String, int> inDegree = {for (final nodeId in nodes.keys) nodeId: 0};
    for (final edge in acyclicEdges) {
      inDegree[edge.toNode] = inDegree[edge.toNode]! + 1;
    }

    final List<String> order = inDegree.keys.where((nodeId) => inDegree[nodeId] == 0).toList();
    for (int i = 0; i < order.length; i++) {
      for (final edge in outgoing[order[i]] ?? const <RoutingEdge>[]) {
        inDegree[edge.toNode] = inDegree[edge.toNode]! - 1;
        if (inDegree[edge.toNode] == 0) order.add(edge.toNode);
      }
    }
    return order;
  }

  Map<PrintSize, Set<String>> _reachablePrinters(List<RoutingEdge> edges) {
    // Only follow edges that carry jobs; value edges such as margins do not route anything.
    final outgoing = edges
        .where((edge) => nodes[edge.toNode]!.data.port(edge.toPort)!.types.any(jobPortTypes.contains))
        .groupListsBy((edge) => (edge.fromNode, edge.fromPort));
    final Set<String> incompletePrinterIds = {};

    Set<String> printersFrom(PrintSize size) {
      final Set<String> visited = {}, printers = {};
      final List<RoutingEdge> pending = [...?outgoing[(sourceId, RoutingPorts.source(size))]];

      while (pending.isNotEmpty) {
        final nodeId = pending.removeLast().toNode;
        if (!visited.add(nodeId)) continue;

        final data = nodes[nodeId]!.data;
        if (data is PrinterNodeData) {
          if (_isComplete(data)) {
            printers.add(nodeId);
          } else {
            incompletePrinterIds.add(nodeId);
          }
          continue;
        }
        for (final port in data.ports.where((port) => port.direction == RoutingPortDirection.output)) {
          pending.addAll(outgoing[(nodeId, port.id)] ?? const []);
        }
      }
      return printers;
    }

    final reachable = {for (final size in PrintSize.values) size: printersFrom(size)};

    for (final nodeId in nodes.keys.where(incompletePrinterIds.contains)) {
      issues.add(RoutingIssue(kind: RoutingIssueKind.incompletePrinter, nodeId: nodeId));
    }
    for (final MapEntry(key: size, value: printers) in reachable.entries) {
      if (printers.isEmpty) issues.add(RoutingIssue(kind: RoutingIssueKind.unroutedPrintSize, printSize: size));
    }
    return reachable;
  }

  static bool _isFull(RoutingPortSpec port, int connectionCount) {
    final maxConnections = port.maxConnections;
    return maxConnections != null && connectionCount >= maxConnections;
  }

  static bool _isComplete(PrinterNodeData printer) {
    final bool hasMediaName = printer.backend != PrinterBackend.cups || printer.media.name.isNotEmpty;
    return printer.queueId.isNotEmpty && hasMediaName && printer.media.widthMm > 0 && printer.media.heightMm > 0;
  }

}
