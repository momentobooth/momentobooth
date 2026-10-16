import 'package:flutter_test/flutter_test.dart';
import 'package:momento_booth/hardware_control/printing/print_routing_analysis.dart';
import 'package:momento_booth/models/print_routing_graph.dart';
import 'package:momento_booth/models/settings.dart';

const _printer = RoutingNodeData.printer(queueId: 'queue', media: PrintMedia(widthMm: 100, heightMm: 148));

RoutingNode _node(String id, RoutingNodeData data) => RoutingNode(id: id, data: data);

RoutingEdge _edge(String fromNode, String fromPort, String toNode, [String toPort = RoutingPorts.input]) =>
    RoutingEdge(fromNode: fromNode, fromPort: fromPort, toNode: toNode, toPort: toPort);

/// Edges that route every print size from 'source' to 'printer'.
List<RoutingEdge> _routeAllSizes() => [
  for (final size in PrintSize.values) _edge('source', RoutingPorts.source(size), 'printer'),
];

List<RoutingIssueKind> _errorKinds(PrintRoutingGraph graph) =>
    PrintRoutingAnalysis.of(graph).errors.map((issue) => issue.kind).toList();

void main() {
  group('PrintRoutingAnalysis', () {
    test('finds the printers each print size reaches', () {
      final analysis = PrintRoutingAnalysis.of(PrintRoutingGraph(
        nodes: [
          _node('source', const RoutingNodeData.source()),
          _node('robin', const RoutingNodeData.roundRobin()),
          _node('tile', const RoutingNodeData.tileLayout(columns: 2, rows: 2)),
          _node('a', _printer),
          _node('b', _printer),
        ],
        edges: [
          _edge('source', 'normal', 'robin'),
          _edge('robin', 'out', 'a'),
          _edge('robin', 'out', 'b'),
          _edge('source', 'tiny', 'tile'),
          _edge('tile', 'out', 'a'),
        ],
      ));

      expect(analysis.hasErrors, isFalse);
      expect(analysis.reachablePrinterIds[PrintSize.normal], {'a', 'b'});
      expect(analysis.reachablePrinterIds[PrintSize.tiny], {'a'});
      expect(analysis.arbiterTypes, {'robin': RoutingPortType.photo});
      expect(analysis.issues, [
        const RoutingIssue(kind: RoutingIssueKind.unroutedPrintSize, printSize: PrintSize.split),
        const RoutingIssue(kind: RoutingIssueKind.unroutedPrintSize, printSize: PrintSize.small),
      ]);
    });

    test('accepts unconnected nodes', () {
      final analysis = PrintRoutingAnalysis.of(PrintRoutingGraph(
        nodes: [
          _node('source', const RoutingNodeData.source()),
          _node('printer', _printer),
          _node('unused tile', const RoutingNodeData.tileLayout()),
          _node('unused printer', const RoutingNodeData.printer()),
        ],
        edges: _routeAllSizes(),
      ));

      expect(analysis.issues, isEmpty);
    });

    test('reports edges that close a cycle', () {
      final graph = PrintRoutingGraph(
        nodes: [
          _node('source', const RoutingNodeData.source()),
          _node('robin1', const RoutingNodeData.roundRobin()),
          _node('robin2', const RoutingNodeData.roundRobin()),
        ],
        edges: [
          _edge('source', 'normal', 'robin1'),
          _edge('robin1', 'out', 'robin2'),
          _edge('robin2', 'out', 'robin1'),
        ],
      );

      expect(PrintRoutingAnalysis.of(graph).errors, [
        RoutingIssue(kind: RoutingIssueKind.cycle, edge: _edge('robin2', 'out', 'robin1')),
      ]);
    });

    test('passes the job type through arbiters', () {
      final graph = PrintRoutingGraph(
        nodes: [
          _node('source', const RoutingNodeData.source()),
          _node('tile', const RoutingNodeData.tileLayout()),
          _node('robin', const RoutingNodeData.roundRobin()),
          _node('second tile', const RoutingNodeData.tileLayout()),
        ],
        edges: [
          _edge('source', 'small', 'tile'),
          _edge('tile', 'out', 'robin'),
          // A sheet cannot be tiled again.
          _edge('robin', 'out', 'second tile'),
        ],
      );

      expect(PrintRoutingAnalysis.of(graph).errors, [
        RoutingIssue(kind: RoutingIssueKind.incompatibleTypes, edge: _edge('robin', 'out', 'second tile')),
      ]);
    });

    test('rejects mixed job types into one arbiter', () {
      final graph = PrintRoutingGraph(
        nodes: [
          _node('source', const RoutingNodeData.source()),
          _node('tile', const RoutingNodeData.tileLayout()),
          _node('robin', const RoutingNodeData.roundRobin()),
        ],
        edges: [
          _edge('source', 'normal', 'robin'),
          _edge('source', 'small', 'tile'),
          _edge('tile', 'out', 'robin'),
        ],
      );

      expect(PrintRoutingAnalysis.of(graph).errors, [
        RoutingIssue(kind: RoutingIssueKind.incompatibleTypes, edge: _edge('tile', 'out', 'robin')),
      ]);
    });

    test('allows one margins connection per printer, only on its margins port', () {
      final graph = PrintRoutingGraph(
        nodes: [
          _node('margins', const RoutingNodeData.margins()),
          _node('other margins', const RoutingNodeData.margins()),
          _node('printer', _printer),
        ],
        edges: [
          _edge('margins', 'margins', 'printer', 'margins'),
          _edge('other margins', 'margins', 'printer', 'margins'),
          _edge('margins', 'margins', 'printer'),
        ],
      );

      expect(_errorKinds(graph), [RoutingIssueKind.tooManyConnections, RoutingIssueKind.incompatibleTypes]);
    });

    test('rejects edges that do not connect an output to an existing input', () {
      final graph = PrintRoutingGraph(
        nodes: [
          _node('source', const RoutingNodeData.source()),
          _node('robin', const RoutingNodeData.roundRobin()),
          _node('printer', _printer),
        ],
        edges: [
          _edge('missing', 'out', 'printer'),
          _edge('robin', 'out1', 'printer'),
          _edge('printer', 'in', 'robin'),
          _edge('source', 'normal', 'printer'),
          _edge('source', 'normal', 'printer'),
        ],
      );

      expect(_errorKinds(graph), [
        RoutingIssueKind.unknownNode,
        RoutingIssueKind.unknownPort,
        RoutingIssueKind.wrongDirection,
        RoutingIssueKind.duplicateEdge,
      ]);
    });

    test('rejects duplicate node IDs and invalid parameters', () {
      final graph = PrintRoutingGraph(nodes: [
        _node('tile', const RoutingNodeData.tileLayout(columns: 0)),
        _node('tile', const RoutingNodeData.roundRobin()),
        _node('other tile', const RoutingNodeData.tileLayout(rows: 0)),
      ]);

      expect(PrintRoutingAnalysis.of(graph).errors, const [
        RoutingIssue(kind: RoutingIssueKind.invalidParameter, nodeId: 'tile'),
        RoutingIssue(kind: RoutingIssueKind.duplicateNodeId, nodeId: 'tile'),
        RoutingIssue(kind: RoutingIssueKind.invalidParameter, nodeId: 'other tile'),
      ]);
    });

    test('warns about incomplete printers that receive jobs and does not route to them', () {
      final analysis = PrintRoutingAnalysis.of(PrintRoutingGraph(
        nodes: [
          _node('source', const RoutingNodeData.source()),
          _node('printer', const RoutingNodeData.printer(backend: PrinterBackend.cups, queueId: 'queue', media: PrintMedia(widthMm: 100, heightMm: 148))),
        ],
        edges: _routeAllSizes(),
      ));

      expect(analysis.reachablePrinterIds.values, everyElement(isEmpty));
      expect(analysis.issues.first, const RoutingIssue(kind: RoutingIssueKind.incompletePrinter, nodeId: 'printer'));
    });
  });

  group('PrintRoutingAnalysis.checkConnection', () {
    final graph = PrintRoutingGraph(
      nodes: [
        _node('source', const RoutingNodeData.source()),
        _node('robin', const RoutingNodeData.roundRobin()),
        _node('tile', const RoutingNodeData.tileLayout()),
        _node('printer', _printer),
      ],
      edges: [
        _edge('robin', 'out', 'tile'),
        _edge('tile', 'out', 'printer'),
      ],
    );

    test('allows a valid connection', () {
      expect(PrintRoutingAnalysis.checkConnection(graph, _edge('source', 'normal', 'robin')), isNull);
    });

    test('rejects a connection that creates a cycle', () {
      expect(PrintRoutingAnalysis.checkConnection(graph, _edge('tile', 'out', 'robin'))?.kind, RoutingIssueKind.cycle);
    });

    test('rejects a connection that makes a downstream edge incompatible', () {
      final withSecondTile = graph.copyWith(nodes: [...graph.nodes, _node('second tile', const RoutingNodeData.tileLayout())]);
      final issue = PrintRoutingAnalysis.checkConnection(withSecondTile, _edge('second tile', 'out', 'robin'));

      expect(issue, RoutingIssue(kind: RoutingIssueKind.incompatibleTypes, edge: _edge('robin', 'out', 'tile')));
    });
  });
}
