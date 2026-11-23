import 'package:flutter_test/flutter_test.dart';
import 'package:momento_booth/hardware_control/printing/print_router.dart';
import 'package:momento_booth/models/print_routing_graph.dart';
import 'package:momento_booth/models/settings.dart';

RoutingNodeData _printer(String label, {PrintMargins margins = const PrintMargins()}) => RoutingNodeData.printer(
  label: label,
  queueId: label,
  media: const PrintMedia(widthMm: 100, heightMm: 148),
  margins: margins,
);

RoutingNode _node(String id, RoutingNodeData data) => RoutingNode(id: id, data: data);

RoutingEdge _edge(String fromNode, String fromPort, String toNode, [String toPort = RoutingPorts.input]) =>
    RoutingEdge(fromNode: fromNode, fromPort: fromPort, toNode: toNode, toPort: toPort);

List<String> _printers(List<PrintRoute> routes) => [for (final route in routes) route.printerNodeId];

/// Prints the next copy of [size] and returns the routes that took a sheet. The printers in [failing] refuse theirs.
Future<List<PrintRoute>> _copy(PrintRouter router, PrintSize size, {Set<String> failing = const {}}) async {
  final List<PrintRoute> printed = [];
  await router.printCopy(size, (route) async {
    if (failing.contains(route.printerNodeId)) return false;
    printed.add(route);
    return true;
  });
  return printed;
}

void main() {
  group('PrintRouter', () {
    test('alternates between the outputs of a round-robin, per copy', () async {
      final router = PrintRouter(PrintRoutingGraph(
        nodes: [
          _node('source', const RoutingNodeData.source()),
          _node('robin', const RoutingNodeData.roundRobin()),
          _node('a', _printer('a')),
          _node('b', _printer('b')),
        ],
        edges: [_edge('source', 'normal', 'robin'), _edge('robin', 'out', 'a'), _edge('robin', 'out', 'b')],
      ));

      expect([for (int i = 0; i < 3; i++) ..._printers(await _copy(router, PrintSize.normal))], ['a', 'b', 'a']);
      expect(await _copy(router, PrintSize.small), isEmpty);
      expect(router.printableSizes, {PrintSize.normal});
    });

    test('prints a copy on every output of a duplicate, each with its own layout and margins', () async {
      final router = PrintRouter(PrintRoutingGraph(
        nodes: [
          _node('source', const RoutingNodeData.source()),
          _node('duplicate', const RoutingNodeData.duplicate()),
          _node('tile', const RoutingNodeData.tileLayout(columns: 2, rows: 2)),
          _node('margins', const RoutingNodeData.margins(margins: PrintMargins(top: 3))),
          _node('a', _printer('a', margins: const PrintMargins(left: 1))),
          _node('b', _printer('b')),
        ],
        edges: [
          _edge('source', 'normal', 'duplicate'),
          _edge('duplicate', 'out', 'a'),
          _edge('duplicate', 'out', 'tile'),
          _edge('tile', 'out', 'b'),
          _edge('margins', 'margins', 'b', 'margins'),
        ],
      ));

      expect(await _copy(router, PrintSize.normal), [
        PrintRoute(printerNodeId: 'a', printer: _printer('a', margins: const PrintMargins(left: 1)) as PrinterNodeData, margins: const PrintMargins(left: 1)),
        PrintRoute(
          printerNodeId: 'b',
          printer: _printer('b') as PrinterNodeData,
          margins: const PrintMargins(top: 3),
          layout: const RoutingNodeData.tileLayout(columns: 2, rows: 2) as TileLayoutNodeData,
        ),
      ]);
      expect(router.photosPerCopy(PrintSize.normal), 5);
    });

    test('skips outputs that lead to an incomplete printer', () async {
      final router = PrintRouter(PrintRoutingGraph(
        nodes: [
          _node('source', const RoutingNodeData.source()),
          _node('robin', const RoutingNodeData.roundRobin()),
          _node('incomplete', const RoutingNodeData.printer()),
          _node('a', _printer('a')),
        ],
        edges: [_edge('source', 'normal', 'robin'), _edge('robin', 'out', 'incomplete'), _edge('robin', 'out', 'a')],
      ));

      expect([for (int i = 0; i < 2; i++) ..._printers(await _copy(router, PrintSize.normal))], ['a', 'a']);
    });

    test('lets the next output of a round-robin print when a printer fails', () async {
      final router = PrintRouter(PrintRoutingGraph(
        nodes: [
          _node('source', const RoutingNodeData.source()),
          _node('robin', const RoutingNodeData.roundRobin()),
          _node('a', _printer('a')),
          _node('b', _printer('b')),
          _node('c', _printer('c')),
        ],
        edges: [
          _edge('source', 'normal', 'robin'),
          _edge('robin', 'out', 'a'),
          _edge('robin', 'out', 'b'),
          _edge('robin', 'out', 'c'),
        ],
      ));

      // b fails on its turn, so c prints that copy and the next copy starts after c.
      expect(_printers(await _copy(router, PrintSize.normal, failing: {'b'})), ['a']);
      expect(_printers(await _copy(router, PrintSize.normal, failing: {'b'})), ['c']);
      expect(_printers(await _copy(router, PrintSize.normal, failing: {'b'})), ['a']);
      expect(await router.printCopy(PrintSize.normal, (_) async => false), isFalse);
    });

    test('prints on the other outputs of a duplicate when a printer fails', () async {
      final router = PrintRouter(PrintRoutingGraph(
        nodes: [
          _node('source', const RoutingNodeData.source()),
          _node('duplicate', const RoutingNodeData.duplicate()),
          _node('a', _printer('a')),
          _node('b', _printer('b')),
        ],
        edges: [_edge('source', 'normal', 'duplicate'), _edge('duplicate', 'out', 'a'), _edge('duplicate', 'out', 'b')],
      ));

      expect(_printers(await _copy(router, PrintSize.normal, failing: {'a'})), ['b']);
      expect(await router.printCopy(PrintSize.normal, (route) async => route.printerNodeId == 'b'), isTrue);
      expect(await router.printCopy(PrintSize.normal, (_) async => false), isFalse);
    });

    test('ignores connections with problems', () async {
      final router = PrintRouter(PrintRoutingGraph(
        nodes: [
          _node('source', const RoutingNodeData.source()),
          _node('tile', const RoutingNodeData.tileLayout()),
          _node('margins', const RoutingNodeData.margins()),
          _node('a', _printer('a')),
        ],
        edges: [_edge('source', 'normal', 'a'), _edge('source', 'small', 'tile'), _edge('margins', 'margins', 'a')],
      ));

      expect(router.analysis.hasErrors, isTrue);
      expect(_printers(await _copy(router, PrintSize.normal)), ['a']);
      expect(await _copy(router, PrintSize.small), isEmpty);
    });

    test('prints split photos in halves, without the tile layout on their route', () async {
      final router = PrintRouter(PrintRoutingGraph(
        nodes: [
          _node('source', const RoutingNodeData.source()),
          _node('tile', const RoutingNodeData.tileLayout(columns: 2)),
          _node('a', _printer('a')),
        ],
        edges: [_edge('source', 'split', 'tile'), _edge('tile', 'out', 'a')],
      ));

      expect((await _copy(router, PrintSize.split)).single.layout, isNull);
      expect(router.photosPerCopy(PrintSize.split), 1);
    });

    test('only knows the photos per copy when every route agrees', () {
      PrintRouter routerWith(TileLayoutNodeData layout) => PrintRouter(PrintRoutingGraph(
        nodes: [
          _node('source', const RoutingNodeData.source()),
          _node('robin', const RoutingNodeData.roundRobin()),
          _node('tile', layout),
          _node('a', _printer('a')),
          _node('b', _printer('b')),
        ],
        edges: [
          _edge('source', 'small', 'robin'),
          _edge('robin', 'out', 'a'),
          _edge('robin', 'out', 'tile'),
          _edge('tile', 'out', 'b'),
        ],
      ));

      expect(routerWith(const RoutingNodeData.tileLayout(columns: 2) as TileLayoutNodeData).photosPerCopy(PrintSize.small), isNull);
      expect(routerWith(const RoutingNodeData.tileLayout() as TileLayoutNodeData).photosPerCopy(PrintSize.small), 1);
      expect(routerWith(const RoutingNodeData.tileLayout() as TileLayoutNodeData).photosPerCopy(PrintSize.tiny), isNull);
    });
  });

  group('PrintRouter with stacks', () {
    test('marks copies that pass a stack with the stack', () async {
      final router = PrintRouter(PrintRoutingGraph(
        nodes: [
          _node('source', const RoutingNodeData.source()),
          _node('stack', const RoutingNodeData.stack(lanes: 2)),
          _node('a', _printer('a')),
        ],
        edges: [_edge('source', 'normal', 'stack'), _edge('stack', 'out', 'a')],
      ));

      expect(await _copy(router, PrintSize.normal), [
        PrintRoute(
          printerNodeId: 'a',
          printer: _printer('a') as PrinterNodeData,
          margins: const PrintMargins(),
          stackNodeId: 'stack',
          stack: const RoutingNodeData.stack(lanes: 2) as StackNodeData,
        ),
      ]);
      expect(router.photosPerCopy(PrintSize.normal), 1);
    });

    test('alternates between stacks behind a round-robin', () async {
      final router = PrintRouter(PrintRoutingGraph(
        nodes: [
          _node('source', const RoutingNodeData.source()),
          _node('robin', const RoutingNodeData.roundRobin()),
          _node('stack a', const RoutingNodeData.stack()),
          _node('stack b', const RoutingNodeData.stack()),
          _node('a', _printer('a')),
          _node('b', _printer('b')),
        ],
        edges: [
          _edge('source', 'normal', 'robin'),
          _edge('robin', 'out', 'stack a'),
          _edge('robin', 'out', 'stack b'),
          _edge('stack a', 'out', 'a'),
          _edge('stack b', 'out', 'b'),
        ],
      ));

      final stacks = [for (int i = 0; i < 3; i++) for (final route in await _copy(router, PrintSize.normal)) route.stackNodeId];
      expect(stacks, ['stack a', 'stack b', 'stack a']);
    });
  });

  group('choosablePrintSizes', () {
    test('offers the routed sizes, without split', () {
      expect(choosablePrintSizes(PrintSize.values.toSet(), isThreePhotoCollage: false), [PrintSize.normal, PrintSize.small, PrintSize.tiny]);
      expect(choosablePrintSizes({PrintSize.small}, isThreePhotoCollage: true), [PrintSize.small]);
    });

    test('offers normal for a collage of three photos when only split is routed', () {
      expect(choosablePrintSizes({PrintSize.split}, isThreePhotoCollage: true), [PrintSize.normal]);
      expect(choosablePrintSizes({PrintSize.split}, isThreePhotoCollage: false), isEmpty);
    });
  });
}
