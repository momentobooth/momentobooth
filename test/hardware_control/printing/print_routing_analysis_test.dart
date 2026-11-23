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

    test('does not route through a tile layout with an invalid grid', () {
      final analysis = PrintRoutingAnalysis.of(PrintRoutingGraph(
        nodes: [
          _node('source', const RoutingNodeData.source()),
          _node('tile', const RoutingNodeData.tileLayout(columns: 0)),
          _node('printer', _printer),
        ],
        edges: [
          _edge('source', 'small', 'tile'),
          _edge('tile', 'out', 'printer'),
        ],
      ));

      expect(analysis.errors.map((issue) => issue.kind), [RoutingIssueKind.invalidParameter]);
      expect(analysis.reachablePrinterIds[PrintSize.small], isEmpty);
      expect(analysis.routableEdges, isEmpty);
    });

    test('routes several print sizes through a stack, which only connects to a printer', () {
      final analysis = PrintRoutingAnalysis.of(PrintRoutingGraph(
        nodes: [
          _node('source', const RoutingNodeData.source()),
          _node('stack', const RoutingNodeData.stack()),
          _node('other stack', const RoutingNodeData.stack()),
          _node('robin', const RoutingNodeData.roundRobin()),
          _node('printer', _printer),
        ],
        edges: [
          _edge('source', 'normal', 'stack'),
          _edge('source', 'split', 'stack'),
          _edge('stack', 'out', 'printer'),
          _edge('source', 'small', 'other stack'),
          _edge('other stack', 'out', 'robin'),
          _edge('robin', 'out', 'printer'),
        ],
      ));

      expect(analysis.errors, [
        RoutingIssue(kind: RoutingIssueKind.incompatibleTypes, edge: _edge('other stack', 'out', 'robin')),
      ]);
      expect(analysis.reachablePrinterIds[PrintSize.normal], {'printer'});
      expect(analysis.reachablePrinterIds[PrintSize.split], {'printer'});
      expect(analysis.reachablePrinterIds[PrintSize.small], isEmpty);
    });

    test('does not route through a stack without columns or with a negative gap', () {
      for (final stack in const [RoutingNodeData.stack(columns: 0), RoutingNodeData.stack(gap: -1)]) {
        final analysis = PrintRoutingAnalysis.of(PrintRoutingGraph(
          nodes: [
            _node('source', const RoutingNodeData.source()),
            _node('stack', stack),
            _node('printer', _printer),
          ],
          edges: [_edge('source', 'normal', 'stack'), _edge('stack', 'out', 'printer')],
        ));

        expect(analysis.errors, const [RoutingIssue(kind: RoutingIssueKind.invalidParameter, nodeId: 'stack')]);
        expect(analysis.reachablePrinterIds[PrintSize.normal], isEmpty);
      }
    });

    test('does not print with margins that leave no room on the media', () {
      PrintRoutingAnalysis analyze({required PrintMargins own, PrintMargins? connected}) => PrintRoutingAnalysis.of(PrintRoutingGraph(
        nodes: [
          _node('source', const RoutingNodeData.source()),
          _node('printer', RoutingNodeData.printer(queueId: 'queue', media: const PrintMedia(widthMm: 100, heightMm: 148), margins: own)),
          if (connected != null) _node('margins', RoutingNodeData.margins(margins: connected)),
        ],
        edges: [
          _edge('source', 'normal', 'printer'),
          if (connected != null) _edge('margins', 'margins', 'printer', 'margins'),
        ],
      ));
      const tooWide = PrintMargins(left: 50, right: 50), tooHigh = PrintMargins(top: 100, bottom: 48), fits = PrintMargins(left: 49, right: 50);

      for (final margins in [tooWide, tooHigh]) {
        final analysis = analyze(own: margins);
        expect(analysis.errors, [const RoutingIssue(kind: RoutingIssueKind.marginsTooLarge, nodeId: 'printer')]);
        expect(analysis.reachablePrinterIds[PrintSize.normal], isEmpty);
      }
      expect(analyze(own: fits).reachablePrinterIds[PrintSize.normal], {'printer'});

      // The margins of a connected margins node replace those of the printer.
      expect(analyze(own: fits, connected: tooWide).reachablePrinterIds[PrintSize.normal], isEmpty);
      expect(analyze(own: tooWide, connected: fits).reachablePrinterIds[PrintSize.normal], {'printer'});
    });

    test('warns when split prints are routed and normal prints are not', () {
      final analysis = PrintRoutingAnalysis.of(PrintRoutingGraph(
        nodes: [
          _node('source', const RoutingNodeData.source()),
          _node('printer', _printer),
        ],
        edges: [_edge('source', 'split', 'printer')],
      ));

      expect(
        analysis.issues,
        contains(const RoutingIssue(kind: RoutingIssueKind.splitWithoutNormal, nodeId: 'source', printSize: PrintSize.normal)),
      );
      expect(analysis.hasErrors, isFalse);
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

    test('knows whether any printer is set up, connected or not', () {
      PrintRoutingAnalysis analyze(List<RoutingNode> printers) => PrintRoutingAnalysis.of(PrintRoutingGraph(
        nodes: [_node('source', const RoutingNodeData.source()), ...printers],
        edges: const [],
      ));

      expect(PrintRoutingAnalysis.of(PrintRoutingGraph.withDefaults()).hasConfiguredPrinter, isFalse);
      expect(analyze([_node('empty', const RoutingNodeData.printer())]).hasConfiguredPrinter, isFalse);
      expect(analyze([_node('unconnected', _printer)]).hasConfiguredPrinter, isTrue);
    });

    test('reports edges that close a cycle', () {
      final graph = PrintRoutingGraph(
        nodes: [
          _node('source', const RoutingNodeData.source()),
          _node('robin1', const RoutingNodeData.roundRobin()),
          _node('robin2', const RoutingNodeData.roundRobin()),
        ],
        edges: [
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

    test('takes a single input per arbiter, so print sizes only come together at printers', () {
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
        RoutingIssue(kind: RoutingIssueKind.tooManyConnections, edge: _edge('tile', 'out', 'robin')),
      ]);
    });

    test('allows one margins connection per printer, only on its margins port', () {
      final graph = PrintRoutingGraph(
        nodes: [
          _node('source', const RoutingNodeData.source()),
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
        _node('source', const RoutingNodeData.source()),
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

    test('passes the job type through a duplicate, which reaches all its outputs', () {
      final analysis = PrintRoutingAnalysis.of(PrintRoutingGraph(
        nodes: [
          _node('source', const RoutingNodeData.source()),
          _node('duplicate', const RoutingNodeData.duplicate()),
          _node('tile', const RoutingNodeData.tileLayout()),
          _node('a', _printer),
          _node('b', _printer),
        ],
        edges: [
          _edge('source', 'normal', 'duplicate'),
          _edge('duplicate', 'out', 'a'),
          _edge('duplicate', 'out', 'tile'),
          _edge('tile', 'out', 'b'),
        ],
      ));

      expect(analysis.errors, isEmpty);
      expect(analysis.arbiterTypes, {'duplicate': RoutingPortType.photo});
      expect(analysis.reachablePrinterIds[PrintSize.normal], {'a', 'b'});
    });

    test('allows a single connection on job outputs other than those of arbiters', () {
      final graph = PrintRoutingGraph(
        nodes: [
          _node('source', const RoutingNodeData.source()),
          _node('a', _printer),
          _node('b', _printer),
        ],
        edges: [_edge('source', 'normal', 'a'), _edge('source', 'normal', 'b')],
      );

      expect(_errorKinds(graph), [RoutingIssueKind.tooManyConnections]);
    });

    test('warns about a tile layout on the route of split prints', () {
      final analysis = PrintRoutingAnalysis.of(PrintRoutingGraph(
        nodes: [
          _node('source', const RoutingNodeData.source()),
          _node('tile', const RoutingNodeData.tileLayout(columns: 2)),
          _node('printer', _printer),
        ],
        edges: [_edge('source', 'split', 'tile'), _edge('tile', 'out', 'printer')],
      ));

      expect(analysis.issues, contains(const RoutingIssue(kind: RoutingIssueKind.ignoredLayout, nodeId: 'tile', printSize: PrintSize.split)));
    });

    test('routes normal prints of the default graph to its printer, once configured', () {
      final defaults = PrintRoutingGraph.withDefaults();
      final configured = defaults.copyWith(nodes: [
        for (final node in defaults.nodes)
          if (node.data is PrinterNodeData) node.copyWith(data: _printer) else node,
      ]);

      expect(PrintRoutingAnalysis.of(defaults).issues, contains(const RoutingIssue(kind: RoutingIssueKind.incompletePrinter, nodeId: 'printer')));
      expect(PrintRoutingAnalysis.of(configured).errors, isEmpty);
      expect(PrintRoutingAnalysis.of(configured).reachablePrinterIds[PrintSize.normal], {'printer'});
    });

    test('requires a source', () {
      final graph = PrintRoutingGraph(nodes: [_node('printer', _printer)]);

      expect(_errorKinds(graph), [RoutingIssueKind.missingSource]);
    });

    test('rejects additional sources and only routes from the first', () {
      final analysis = PrintRoutingAnalysis.of(PrintRoutingGraph(
        nodes: [
          _node('source', const RoutingNodeData.source()),
          _node('second source', const RoutingNodeData.source()),
          _node('printer', _printer),
        ],
        edges: [_edge('second source', 'normal', 'printer')],
      ));

      expect(analysis.errors, const [RoutingIssue(kind: RoutingIssueKind.duplicateSource, nodeId: 'second source')]);
      expect(analysis.reachablePrinterIds[PrintSize.normal], isEmpty);
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

    test('allows a connection that replaces the connection of a single-connection port', () {
      // The tile input is already connected to the round-robin.
      expect(PrintRoutingAnalysis.checkConnection(graph, _edge('source', 'small', 'tile')), isNull);
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
