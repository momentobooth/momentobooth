import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:momento_booth/hardware_control/printing/print_job_runner.dart';
import 'package:momento_booth/hardware_control/printing/print_router.dart';
import 'package:momento_booth/hardware_control/printing/stack_collector.dart';
import 'package:momento_booth/models/print_routing_graph.dart';
import 'package:momento_booth/models/settings.dart';

import 'memory_collected_copy_store.dart';

/// A PNG of one pixel.
final _photo = base64Decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==');

RoutingNodeData _printer(String label) =>
    RoutingNodeData.printer(label: label, queueId: label, media: const PrintMedia(widthMm: 100, heightMm: 148));

RoutingNode _node(String id, RoutingNodeData data) => RoutingNode(id: id, data: data);

RoutingEdge _edge(String fromNode, String fromPort, String toNode) =>
    RoutingEdge(fromNode: fromNode, fromPort: fromPort, toNode: toNode, toPort: RoutingPorts.input);

/// Printers that record what they get. The printers in [failing] throw, and so does every printer once [failFrom]
/// sheets were sent; with [skip], sending is skipped.
class _Printers {

  final Set<String> failing;
  final int? failFrom;
  final bool skip;
  final List<(String printer, String sheetName)> sent = [];
  final List<PrintSize> counted = [];
  final List<String> errors = [];

  _Printers({this.failing = const {}, this.failFrom, this.skip = false});

  PrintJobRunner get runner => PrintJobRunner(
    sendSheet: (sheetName, route, pdf) async {
      if (failing.contains(route.printerNodeId) || sent.length == failFrom) {
        throw Exception('${route.printerNodeId} is out of paper');
      }
      if (skip) return false;
      sent.add((route.printerNodeId, sheetName));
      return true;
    },
    countPrint: counted.add,
    logError: (message, error, stackTrace) => errors.add(message),
  );

  List<String> get printers => [for (final (printer, _) in sent) printer];

}

PrintRouter _router(List<RoutingNode> nodes, List<RoutingEdge> edges) =>
    PrintRouter(PrintRoutingGraph(nodes: [_node('source', const RoutingNodeData.source()), ...nodes], edges: edges));

Future<PrintJobReport> _run(
  _Printers printers,
  PrintRouter router, {
  PrintSize size = PrintSize.normal,
  int copies = 1,
  StackCollector? collector,
  String jobName = 'job',
}) =>
    printers.runner.run(router, jobName: jobName, image: Uint8List.fromList(_photo), size: size, copies: copies, collector: collector);

/// A stack in collect mode with two columns on media of 100 × 148 mm: four copies of the square photo fit on a sheet.
PrintRouter _collectingRouter() => _router(
  [_node('stack', const RoutingNodeData.stack(mode: StackMode.collect, lanes: 2, gap: 0)), _node('a', _printer('a'))],
  [_edge('source', 'normal', 'stack'), _edge('stack', 'out', 'a')],
);

void main() {
  group('PrintJobRunner', () {
    test('prints every copy on its own sheet, and renders a sheet that repeats once', () async {
      final printers = _Printers();
      final report = await _run(printers, _router([_node('a', _printer('a'))], [_edge('source', 'normal', 'a')]), copies: 2);

      expect(report.failure, isNull);
      expect(printers.sent, [('a', 'job | Normal print size | copy 1 / 2'), ('a', 'job | Normal print size | copy 2 / 2')]);
      expect(printers.counted, [PrintSize.normal, PrintSize.normal]);
      expect(report.sentSheets, 2);
      expect(report.renderings, hasLength(1));
      expect([for (final sheet in report.sheets) sheet['copies']], [[1], [2]]);
    });

    test('lets the next output of a round-robin take a copy when a printer fails', () async {
      final printers = _Printers(failing: {'a'});
      final report = await _run(
        printers,
        _router(
          [_node('robin', const RoutingNodeData.roundRobin()), _node('a', _printer('a')), _node('b', _printer('b'))],
          [_edge('source', 'normal', 'robin'), _edge('robin', 'out', 'a'), _edge('robin', 'out', 'b')],
        ),
        copies: 2,
      );

      expect(report.failure, isNull);
      expect(printers.printers, ['b', 'b']);
      expect(report.failedPrinters, {'a'});
      expect(printers.errors, hasLength(2));
      expect([for (final sheet in report.sheets) sheet['error'] != null], [true, false, true, false]);
    });

    test('fails when no printer takes a copy, and tells how many sheets were sent', () async {
      final printers = _Printers(failFrom: 1);
      final report = await _run(printers, _router([_node('a', _printer('a'))], [_edge('source', 'normal', 'a')]), copies: 3);

      expect(report.failure?.message, 'No printer took copy 2 / 3 at Normal print size');
      expect(report.failure?.sentSheets, 1);
      expect(printers.counted, [PrintSize.normal]);
      // Printing stops at the copy no printer takes.
      expect(report.sheets, hasLength(2));
    });

    test('puts the copies that pass a stack on one sheet, sent after all copies are routed', () async {
      final printers = _Printers();
      final report = await _run(
        printers,
        _router(
          [
            _node('duplicate', const RoutingNodeData.duplicate()),
            _node('stack', const RoutingNodeData.stack(lanes: 2)),
            _node('a', _printer('a')),
            _node('b', _printer('b')),
          ],
          [
            _edge('source', 'normal', 'duplicate'),
            _edge('duplicate', 'out', 'stack'),
            _edge('duplicate', 'out', 'b'),
            _edge('stack', 'out', 'a'),
          ],
        ),
        copies: 3,
      );

      expect(report.failure, isNull);
      expect(printers.sent, [
        ('b', 'job | Normal print size | copy 1 / 3'),
        ('b', 'job | Normal print size | copy 2 / 3'),
        ('b', 'job | Normal print size | copy 3 / 3'),
        ('a', 'job | Normal print size | 3 of 3 copies stacked'),
      ]);
      expect(report.sheets.last['copies'], [1, 2, 3]);
      expect(report.sheets.last['stack'], isNotNull);
      // Three on b, and three on the stack's sheet.
      expect(printers.counted, hasLength(6));
    });

    test('fails when the printer of a stack fails, without counting its copies', () async {
      final printers = _Printers(failing: {'a'});
      final report = await _run(
        printers,
        _router(
          [_node('stack', const RoutingNodeData.stack()), _node('a', _printer('a'))],
          [_edge('source', 'normal', 'stack'), _edge('stack', 'out', 'a')],
        ),
        copies: 2,
      );

      expect(report.failure?.message, 'Not all stacked copies at Normal print size were printed');
      expect(report.failedPrinters, {'a'});
      expect(printers.counted, isEmpty);
    });

    test('stacks the halves of a split print', () async {
      final printers = _Printers();
      final report = await _run(
        printers,
        _router(
          [_node('stack', const RoutingNodeData.stack()), _node('a', _printer('a'))],
          [_edge('source', 'split', 'stack'), _edge('stack', 'out', 'a')],
        ),
        size: PrintSize.split,
      );

      expect(report.failure, isNull);
      expect(printers.counted, [PrintSize.split]);
    });

    test('does not count sheets whose sending is skipped', () async {
      final printers = _Printers(skip: true);
      final report = await _run(printers, _router([_node('a', _printer('a'))], [_edge('source', 'normal', 'a')]), copies: 2);

      expect(report.failure, isNull);
      expect(report.sentSheets, 0);
      expect(printers.counted, isEmpty);
      expect(report.renderings, hasLength(1));
    });

    test('fails the first copy when the print size is not routed', () async {
      final report = await _run(_Printers(), _router([_node('a', _printer('a'))], [_edge('source', 'normal', 'a')]), size: PrintSize.small);

      expect(report.failure?.message, 'No printer took copy 1 / 1 at Small print size');
      expect(report.sheets, isEmpty);
    });
  });

  group('PrintJobRunner in collect mode', () {
    test('lets copies wait until their sheet is full, and then prints the copies of several prints together', () async {
      final printers = _Printers();
      final collector = StackCollector(MemoryCollectedCopyStore());
      final router = _collectingRouter();

      final first = await _run(printers, router, collector: collector, jobName: 'first');
      expect(first.failure, isNull);
      expect(first.waitingCopies, 1);
      expect(printers.sent, isEmpty);

      final second = await _run(printers, router, collector: collector, jobName: 'second', copies: 3);
      expect(second.waitingCopies, 0);
      expect(printers.sent, [('a', 'Collected sheet | 4 copies of first, second')]);
      expect(printers.counted, hasLength(4));
      expect(collector.copies, isEmpty);
    });

    test('keeps the copies of a sheet that fails waiting, and prints them with a later sheet', () async {
      final collector = StackCollector(MemoryCollectedCopyStore());
      final router = _collectingRouter();

      final failing = _Printers(failing: {'a'});
      final failed = await _run(failing, router, collector: collector, copies: 4);
      // Not a failure for the guest: the copies wait for the next sheet.
      expect(failed.failure, isNull);
      expect(failed.waitingCopies, 4);
      expect(failed.failedPrinters, {'a'});
      expect(failing.counted, isEmpty);

      final printers = _Printers();
      final later = await _run(printers, router, collector: collector, jobName: 'later');
      expect(printers.sent, [('a', 'Collected sheet | 4 copies of job')]);
      expect(later.waitingCopies, 1);
      expect(collector.copies.single.jobName, 'later');
    });

    test('prints right away without a place to keep waiting copies', () async {
      final printers = _Printers();
      final report = await _run(printers, _collectingRouter());

      expect(report.waitingCopies, 0);
      expect(printers.sent, [('a', 'job | Normal print size | 1 of 1 copies stacked')]);
    });
  });
}
