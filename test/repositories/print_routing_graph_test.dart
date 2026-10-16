import 'package:flutter_test/flutter_test.dart';
import 'package:momento_booth/models/print_routing_graph.dart';
import 'package:toml/toml.dart';

const _graph = PrintRoutingGraph(
  nodes: [
    RoutingNode(id: 'source', data: RoutingNodeData.source()),
    RoutingNode(id: 'robin', x: 300, y: 50, data: RoutingNodeData.roundRobin()),
    RoutingNode(id: 'tile', data: RoutingNodeData.tileLayout(columns: 2, rows: 2, rotate: true)),
    RoutingNode(id: 'margins', data: RoutingNodeData.margins(margins: PrintMargins(top: 1.5, left: 2))),
    RoutingNode(id: 'printer', data: RoutingNodeData.printer(
      label: 'DNP strip',
      backend: PrinterBackend.cups,
      queueId: 'dnp',
      media: PrintMedia(name: 'custom_50x148mm', widthMm: 50, heightMm: 148),
    )),
  ],
  edges: [
    RoutingEdge(fromNode: 'source', fromPort: 'tiny', toNode: 'tile', toPort: 'in'),
    RoutingEdge(fromNode: 'tile', fromPort: 'out', toNode: 'printer', toPort: 'in'),
  ],
);

void main() {
  group('PrintRoutingGraph serialization', () {
    test('survives a TOML round trip', () {
      final toml = TomlDocument.fromMap(_graph.toTomlValue()).toString();
      final decoded = PrintRoutingGraph.fromJson(TomlDocument.parse(toml).toMap());

      expect(decoded, _graph);
    });

    test('identifies node types by their type key', () {
      final nodes = (_graph.toJson()['nodes'] as List).cast<Map<String, dynamic>>();
      final types = [for (final node in nodes) (node['data'] as Map<String, dynamic>)['type']];

      expect(types, ['source', 'roundRobin', 'tileLayout', 'margins', 'printer']);
    });

    test('defaults absent fields', () {
      final graph = PrintRoutingGraph.fromJson({
        'nodes': [
          {'id': 'printer', 'data': {'type': 'printer'}},
        ],
      });

      expect(graph.edges, isEmpty);
      expect(graph.nodes.single, const RoutingNode(id: 'printer', data: RoutingNodeData.printer()));
    });

    test('stores positions in whole pixels', () {
      final json = const RoutingNode(id: 'robin', x: 12.4, y: 50.5, data: RoutingNodeData.roundRobin()).toJson();

      expect((json['x'], json['y']), (12.0, 51.0));
    });
  });

  group('PrintRoutingGraph.withSource', () {
    test('adds a source with an unused ID when there is none', () {
      const graph = PrintRoutingGraph(nodes: [RoutingNode(id: 'source', data: RoutingNodeData.roundRobin())]);

      expect(graph.withSource().nodes.first, const RoutingNode(id: 'source_1', data: RoutingNodeData.source()));
    });

    test('keeps a graph that has a source', () {
      expect(_graph.withSource(), same(_graph));
    });
  });

  group('PrintRoutingGraph.withEdge', () {
    const tinyToTile = RoutingEdge(fromNode: 'source', fromPort: 'tiny', toNode: 'tile', toPort: 'in');
    const smallToTile = RoutingEdge(fromNode: 'source', fromPort: 'small', toNode: 'tile', toPort: 'in');
    const normalToPrinter = RoutingEdge(fromNode: 'source', fromPort: 'normal', toNode: 'printer', toPort: 'in');

    test('replaces the connection of a single-connection port', () {
      expect(_graph.withEdge(smallToTile).edges, isNot(contains(tinyToTile)));
      expect(_graph.withEdge(smallToTile).edges.last, smallToTile);
    });

    test('adds to ports without a connection limit', () {
      expect(_graph.withEdge(normalToPrinter).edges, [..._graph.edges, normalToPrinter]);
    });
  });

  group('RoutingNodeData.ports', () {
    test('gives the source node an output per print size', () {
      expect(const RoutingNodeData.source().ports.map((port) => port.id), ['normal', 'split', 'small', 'tiny']);
    });
  });
}
