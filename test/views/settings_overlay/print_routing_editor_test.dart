import 'package:fl_nodes_v2/fl_nodes_v2.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:momento_booth/models/print_queue_info.dart';
import 'package:momento_booth/models/print_routing_graph.dart';
import 'package:momento_booth/src/rust/utils/ipp_client.dart';
import 'package:momento_booth/views/settings_overlay/components/print_routing_editor/print_routing_editor.dart';
import 'package:momento_booth/views/settings_overlay/components/print_routing_editor/print_routing_editor_view_model.dart';
import 'package:momento_booth/views/settings_overlay/components/print_routing_editor/print_routing_hardware.dart';
import 'package:momento_booth/views/settings_overlay/components/print_routing_editor/print_routing_node_card.dart';
import 'package:momento_booth/views/settings_overlay/components/print_routing_editor/print_routing_node_layout.dart';

class _FakeHardware implements PrintRoutingHardware {

  int queueListings = 0;
  int mediaListings = 0;

  @override
  Future<List<PrintQueueInfo>> listQueues(PrinterBackend backend) async {
    queueListings++;
    return switch (backend) {
      PrinterBackend.native => const [PrintQueueInfo(id: 'canon', name: 'Canon SELPHY', isAvailable: true)],
      PrinterBackend.cups => const [PrintQueueInfo(id: 'dnp', name: 'DNP DS620', isAvailable: true)],
    };
  }

  @override
  Future<List<PrintDimension>> listCupsMedia(String queueId) async {
    mediaListings++;
    return const [
      PrintDimension(name: '4x6', width: 101.6, height: 152.4, keyword: 'na_index-4x6_4x6in'),
      PrintDimension(name: '2x6', width: 50.8, height: 152.4, keyword: 'custom_2x6'),
    ];
  }

}

RoutingEdge _edge(String fromNode, String fromPort, String toNode, [String toPort = RoutingPorts.input]) =>
    RoutingEdge(fromNode: fromNode, fromPort: fromPort, toNode: toNode, toPort: toPort);

final _graph = PrintRoutingGraph(
  nodes: const [
    RoutingNode(id: 'source', data: RoutingNodeData.source()),
    RoutingNode(id: 'robin', x: 260, data: RoutingNodeData.roundRobin()),
    RoutingNode(id: 'tile', x: 260, y: 200, data: RoutingNodeData.tileLayout(columns: 2)),
    RoutingNode(id: 'margins', x: 260, y: 460, data: RoutingNodeData.margins()),
    RoutingNode(id: 'canon', x: 600, data: RoutingNodeData.printer(
      label: 'Canon',
      queueId: 'canon',
      media: PrintMedia(widthMm: 100, heightMm: 148),
    )),
    RoutingNode(id: 'dnp', x: 600, y: 560, data: RoutingNodeData.printer(
      label: 'DNP',
      backend: PrinterBackend.cups,
      queueId: 'dnp',
      media: PrintMedia(name: 'custom_2x6', widthMm: 50.8, heightMm: 152.4),
    )),
  ],
  edges: [
    _edge('source', 'normal', 'robin'),
    _edge('robin', RoutingPorts.output, 'canon'),
    _edge('source', 'small', 'tile'),
    _edge('tile', RoutingPorts.output, 'dnp'),
    _edge('margins', RoutingPorts.margins, 'dnp', RoutingPorts.margins),
  ],
);

/// Lets the microtasks of the view model run: hints and the re-derivation of node shapes.
Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  group('RoutingNodeLayout', () {
    test('puts the margins port of a printer at its margins section', () {
      const layout = RoutingNodeLayout(RoutingNodeData.printer(), marginsWired: false, noteRows: 1);
      final marginsPort = const RoutingNodeData.printer().port(RoutingPorts.margins)!;

      // Header, the job port row and four field rows (label, backend, printer, size) precede the caption row.
      const captionTop = RoutingNodeMetrics.headerHeight + RoutingNodeMetrics.portRowHeight + 4 * RoutingNodeMetrics.fieldRowHeight;
      expect(layout.portCenter(marginsPort), captionTop + RoutingNodeMetrics.captionRowHeight / 2);
      expect(
        layout.height,
        captionTop + RoutingNodeMetrics.captionRowHeight + 2 * RoutingNodeMetrics.fieldRowHeight +
            RoutingNodeMetrics.noteRowHeight + RoutingNodeMetrics.bottomPadding,
      );
    });
  });

  group('PrintRoutingEditorViewModel', () {
    late PrintRoutingEditorViewModel viewModel;
    late List<PrintRoutingGraph> saved;
    late _FakeHardware hardware;

    setUp(() {
      saved = [];
      hardware = _FakeHardware();
      viewModel = PrintRoutingEditorViewModel(_graph, onGraphChanged: saved.add, hardware: hardware);
    });
    tearDown(() => viewModel.dispose());

    NodeEditorController editor() => viewModel.editor;

    test('loads the graph without changing or saving it', () {
      expect(viewModel.graph, _graph);
      expect(toPrintRoutingGraph(editor().graph), _graph);
      expect(saved, isEmpty);
    });

    test('refuses incompatible connections and explains the ones the port colours do not', () async {
      // Checked by the library: margins into a photo input.
      expect(editor().canConnect(const PortRef('margins', 'margins'), const PortRef('tile', 'in')), isFalse);

      // Checked by the analysis, but evident from the colours: margins into the job input of a printer.
      expect(editor().canConnect(const PortRef('margins', 'margins'), const PortRef('canon', 'in')), isFalse);
      await _settle();
      expect(viewModel.connectionHint, isNull);

      // A sheet into a round-robin that carries photos.
      expect(editor().canConnect(const PortRef('tile', 'out'), const PortRef('robin', 'in')), isFalse);
      await _settle();
      expect(viewModel.connectionHint, 'This round-robin already carries photos.');

      // A loop through two round-robins.
      viewModel.addNode(RoutingNodeKind.roundRobin, Offset.zero);
      final robin2 = viewModel.graph.nodes.last.id;
      expect(editor().connect(const PortRef('robin', 'out'), PortRef(robin2, 'in')), isNotNull);
      expect(editor().canConnect(PortRef(robin2, 'out'), const PortRef('robin', 'in')), isFalse);
      await _settle();
      expect(viewModel.connectionHint, 'This connection would create a loop.');

      expect(editor().canConnect(const PortRef('source', 'tiny'), const PortRef('canon', 'in')), isTrue);
      await _settle();
      expect(viewModel.connectionHint, isNull);
    });

    test('replaces the connection of a single-connection port in one undo step', () {
      viewModel.addNode(RoutingNodeKind.margins, Offset.zero);
      final margins2 = viewModel.graph.nodes.last.id;
      Iterable<String> marginsOfDnp() =>
          viewModel.graph.edges.where((edge) => edge.toNode == 'dnp' && edge.toPort == 'margins').map((edge) => edge.fromNode);

      expect(editor().connect(PortRef(margins2, 'margins'), const PortRef('dnp', 'margins')), isNotNull);
      expect(marginsOfDnp(), [margins2]);

      editor().history.undo();
      expect(marginsOfDnp(), ['margins']);
    });

    test('keeps exactly one source', () {
      editor().selection.selectAll();
      viewModel.deleteSelection();
      expect(viewModel.graph.nodes.map((node) => node.id), ['source']);
      editor().history.undo();

      editor().selection.selectAll();
      viewModel
        ..duplicateSelection()
        ..copySelection()
        ..paste();
      expect(viewModel.graph.nodes.where((node) => node.data is SourceNodeData), hasLength(1));
      expect(viewModel.graph.nodes, hasLength(_graph.nodes.length * 3 - 2));

      viewModel.removeNode('source');
      expect(viewModel.graph.nodes.map((node) => node.id), contains('source'));
    });

    test('empties the clipboard when only the source is copied', () {
      editor().selection.selectNode('tile');
      viewModel.copySelection();
      editor().selection.selectNode('source');
      viewModel
        ..copySelection()
        ..paste();

      expect(viewModel.graph.nodes, hasLength(_graph.nodes.length));
    });

    test('lists printers and media again on refresh', () async {
      await viewModel.loadQueues();
      viewModel.ensureCupsMedia('dnp');
      await _settle();
      expect((hardware.queueListings, hardware.mediaListings), (2, 1));

      await viewModel.refreshPrinters();
      await _settle();
      expect((hardware.queueListings, hardware.mediaListings), (4, 2));
      expect(viewModel.cupsMedia['dnp'], hasLength(2));
    });

    test('colours a port that accepts several types after what is connected to it', () async {
      Color? jobPortColor() => editor().graph.nodes['canon']!.portById('in')!.color;
      expect(jobPortColor(), routingPortTypeColor(RoutingPortType.photo));

      editor().removeConnections([editor().graph.connectionsAt(const PortRef('canon', 'in')).single.id]);
      expect(editor().connect(const PortRef('tile', 'out'), const PortRef('canon', 'in')), isNotNull);
      await _settle();
      expect(jobPortColor(), routingPortTypeColor(RoutingPortType.sheet));

      expect(editor().connect(const PortRef('source', 'tiny'), const PortRef('canon', 'in')), isNotNull);
      await _settle();
      expect(jobPortColor(), isNull);
    });
  });

  group('PrintRoutingEditor', () {
    late List<PrintRoutingGraph> saved;
    late _FakeHardware hardware;

    Future<void> pumpEditor(WidgetTester tester) async {
      saved = [];
      hardware = _FakeHardware();
      tester.view
        ..physicalSize = const Size(1920, 1080)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(FluentApp(
        home: Padding(
          padding: const EdgeInsets.all(16),
          child: PrintRoutingEditor(initialGraph: _graph, onGraphChanged: saved.add, hardware: hardware),
        ),
      ));
      await tester.pumpAndSettle();
    }

    NodeEditorController editorOf(WidgetTester tester) => tester.widget<NodeEditor>(find.byType(NodeEditor)).controller;

    Finder inNode(String nodeId, Finder finder) => find.descendant(
      of: find.byWidgetPredicate((widget) => widget is RoutingNodeCard && widget.node.id == nodeId),
      matching: finder,
    );

    testWidgets('shows the nodes with their fields and notes', (tester) async {
      await pumpEditor(tester);

      expect(inNode('robin', find.text('Round-robin')), findsOneWidget);
      expect(inNode('robin', find.text('Carries photos')), findsOneWidget);
      expect(inNode('canon', find.text('Canon SELPHY')), findsOneWidget);
      expect(inNode('dnp', find.text('2x6')), findsOneWidget);
      expect(inNode('dnp', find.text('W 50.8 × H 152.4')), findsOneWidget);
      expect(inNode('dnp', find.text('from the connected node')), findsOneWidget);
      expect(inNode('canon', find.text('in mm')), findsOneWidget);
      expect(inNode('source', find.text('Not routed: Split, Tiny')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Delete edits a focused text box, and deletes the selection when the canvas has focus', (tester) async {
      await pumpEditor(tester);
      final editor = editorOf(tester);

      await tester.tap(inNode('canon', find.byType(TextBox)).first);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
      await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
      await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
      await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
      await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
      // The text box is empty now and leaves this one to the editor.
      await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
      await tester.pump();
      expect(editor.graph.nodes, contains('canon'));

      // Clicking the header focuses the canvas again.
      await tester.tap(inNode('canon', find.text('Printer')).first);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.delete);
      await tester.pumpAndSettle();
      expect(editor.graph.nodes, isNot(contains('canon')));
    });

    testWidgets('dragging on a field does not move the node, dragging the header does', (tester) async {
      await pumpEditor(tester);
      final editor = editorOf(tester);
      final start = editor.graph.nodes['canon']!.position;

      await tester.drag(inNode('canon', find.byType(ComboBox<PrinterBackend>)), const Offset(0, 60));
      await tester.pumpAndSettle();
      expect(editor.graph.nodes['canon']!.position, start);

      await tester.drag(inNode('canon', find.byType(TextBox)).first, const Offset(-80, 0));
      await tester.pumpAndSettle();
      expect(editor.graph.nodes['canon']!.position, start);

      await tester.drag(inNode('canon', find.text('Printer')).first, const Offset(0, 60));
      await tester.pumpAndSettle();
      expect(editor.graph.nodes['canon']!.position, isNot(start));
    });

    testWidgets('selecting CUPS media fills in its size', (tester) async {
      await pumpEditor(tester);

      await tester.tap(inNode('dnp', find.byType(ComboBox<String>)).last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('4x6').last);
      await tester.pumpAndSettle();

      final printer = editorOf(tester).graph.nodes['dnp']!.field<RoutingNodeData>(routingDataKey)! as PrinterNodeData;
      expect(printer.media, const PrintMedia(name: 'na_index-4x6_4x6in', widthMm: 101.6, heightMm: 152.4));
      expect(inNode('dnp', find.text('W 101.6 × H 152.4')), findsOneWidget);
    });

    testWidgets('adds nodes from the toolbar', (tester) async {
      await pumpEditor(tester);
      final tileLayouts = find.byWidgetPredicate((widget) => widget is RoutingNodeCard && widget.node.type == 'tileLayout');
      expect(tileLayouts, findsOneWidget);

      await tester.tap(find.ancestor(of: find.text('Tile layout'), matching: find.byType(Button)));
      await tester.pumpAndSettle();
      expect(tileLayouts, findsNWidgets(2));
      expect(find.ancestor(of: find.text('Source'), matching: find.byType(Button)), findsNothing);
    });

    testWidgets('names the node of a problem in the side panel', (tester) async {
      await pumpEditor(tester);
      final editor = editorOf(tester);
      final canon = editor.graph.nodes['canon']!.field<RoutingNodeData>(routingDataKey)! as PrinterNodeData;

      editor.updateNode('canon', (node) => node.withData({routingDataKey: canon.copyWith(queueId: '')}));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(ListTile, 'Printer "Canon"'), findsOneWidget);
    });

    testWidgets('does not offer to add or delete the source', (tester) async {
      await pumpEditor(tester);

      await tester.tapAt(tester.getBottomLeft(find.byType(NodeEditor)) + const Offset(40, -40), buttons: kSecondaryButton);
      await tester.pumpAndSettle();
      expect(find.byType(MenuFlyout), findsOneWidget);
      expect(find.text('Add tile layout'), findsOneWidget);
      expect(find.text('Add source'), findsNothing);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      await tester.tapAt(tester.getCenter(inNode('source', find.text('Source'))), buttons: kSecondaryButton);
      await tester.pumpAndSettle();
      expect(find.byType(MenuFlyout), findsNothing);
    });

    testWidgets('saves edits once they settle, and when closed', (tester) async {
      await pumpEditor(tester);
      final editor = editorOf(tester)
        ..updateNode('tile', (node) => node.withData({routingDataKey: const RoutingNodeData.tileLayout(rows: 3)}))
        ..updateNode('tile', (node) => node.withData({routingDataKey: const RoutingNodeData.tileLayout(rows: 4)}));
      await tester.pump(PrintRoutingEditorViewModelBase.saveDelay);
      expect(saved, hasLength(1));
      expect(saved.single.nodes.firstWhere((node) => node.id == 'tile').data, const RoutingNodeData.tileLayout(rows: 4));

      editor.updateNode('tile', (node) => node.withData({routingDataKey: const RoutingNodeData.tileLayout(rows: 5)}));
      await tester.pumpWidget(const SizedBox());
      expect(saved, hasLength(2));
    });
  });
}
