import 'package:collection/collection.dart';
import 'package:momento_booth/hardware_control/printing/print_routing_analysis.dart';
import 'package:momento_booth/models/print_routing_graph.dart';
import 'package:momento_booth/views/settings_overlay/components/print_routing_editor/print_routing_node_layout.dart';

/// A line shown below the fields of a node card.
class RoutingNodeNote {

  /// Null for information that is not a problem.
  final RoutingIssueSeverity? severity;
  final String text;

  const RoutingNodeNote(this.severity, this.text);

}

String routingNodeName(RoutingNode node) => switch (node.data) {
  PrinterNodeData(:final label) when label.isNotEmpty => 'Printer "$label"',
  PrinterNodeData(backend: PrinterBackend.native) => 'Unnamed native printer',
  PrinterNodeData(backend: PrinterBackend.cups) => 'Unnamed CUPS printer',
  final data => RoutingNodeKind.of(data).label,
};

/// The node an issue is about, to tell issues apart in a list of all of them. Null for issues about the whole graph.
String? routingIssueSubject(RoutingIssue issue, PrintRoutingGraph graph) {
  final nodeId = issue.nodeId ?? issue.edge?.toNode;
  final node = graph.nodes.firstWhereOrNull((node) => node.id == nodeId);
  return node == null ? null : routingNodeName(node);
}

String describeRoutingIssue(RoutingIssue issue, PrintRoutingGraph graph) {
  RoutingNode? nodeById(String? id) => graph.nodes.firstWhereOrNull((node) => node.id == id);
  final edgeSource = nodeById(issue.edge?.fromNode);

  return switch (issue.kind) {
    RoutingIssueKind.duplicateNodeId => 'Two nodes share the ID "${issue.nodeId}".',
    RoutingIssueKind.missingSource => 'There is no source node.',
    RoutingIssueKind.duplicateSource => 'Only one source is used, this one is ignored.',
    RoutingIssueKind.invalidParameter => 'Columns and rows must be at least 1.',
    RoutingIssueKind.unknownNode || RoutingIssueKind.unknownPort || RoutingIssueKind.wrongDirection =>
      'A stored connection is invalid and is ignored.',
    RoutingIssueKind.duplicateEdge => 'A connection is stored twice.',
    RoutingIssueKind.tooManyConnections => 'This input accepts a single connection.',
    RoutingIssueKind.incompatibleTypes =>
      'The connection from ${edgeSource == null ? 'another node' : routingNodeName(edgeSource)} carries the wrong type.',
    RoutingIssueKind.cycle => 'Connections form a loop.',
    RoutingIssueKind.incompletePrinter => switch (nodeById(issue.nodeId)?.data) {
      PrinterNodeData(backend: PrinterBackend.cups) => 'Select a queue and media to print with this printer.',
      _ => 'Select a printer and set the media size to print with it.',
    },
    RoutingIssueKind.unroutedPrintSize => '${printSizeShortLabel(issue.printSize!)} prints are not routed to a printer.',
  };
}

/// The notes of node [nodeId]: its own issues, those of connections that end at it, and for the source the print
/// sizes that are not routed anywhere.
List<RoutingNodeNote> routingNodeNotes(PrintRoutingAnalysis analysis, PrintRoutingGraph graph, String nodeId) {
  final notes = [
    for (final issue in analysis.issues)
      if (issue.kind != RoutingIssueKind.unroutedPrintSize && (issue.nodeId == nodeId || issue.edge?.toNode == nodeId))
        RoutingNodeNote(issue.severity, describeRoutingIssue(issue, graph)),
  ];

  // Not every booth uses every print size, so this is information rather than a warning.
  final activeSource = graph.nodes.firstWhereOrNull((node) => node.data is SourceNodeData);
  if (activeSource?.id == nodeId) {
    final unrouted = [
      for (final issue in analysis.issues)
        if (issue.kind == RoutingIssueKind.unroutedPrintSize) printSizeShortLabel(issue.printSize!),
    ];
    if (unrouted.isNotEmpty) notes.add(RoutingNodeNote(null, 'Not routed: ${unrouted.join(', ')}'));
  }
  return notes;
}
