import 'dart:math' as math;
import 'dart:typed_data';

import 'package:momento_booth/models/print_routing_graph.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// The ruler length the calibration dialog starts with, in mm.
const double defaultCalibrationRulerLength = 25;

/// How far the control lines lie inside and outside the set margins, in mm.
const double calibrationControlDistance = 0.5;

const _pink = PdfColor.fromInt(0xffff3366);
const _dark = PdfColor.fromInt(0xff2e272d);
const _grey = PdfColor.fromInt(0xff6b6469);
const _rulerBand = PdfColor.fromInt(0xffffd6e0);

/// Renders a calibration page on the media of [printer], to measure its margins: the part of the page that does not
/// end up visible on the print, because the printer cuts it off (borderless media) or cannot print there.
///
/// The page has a frame on its edge, and a ruler of [rulerLength] mm from the middle of every edge inwards, with a
/// mark every mm. The first mark that is visible on a side is the margin of that side. The rulers are shortened to
/// half the page when they do not fit.
///
/// To check the set [margins], a line is drawn on them, with a dashed line [calibrationControlDistance] inside and
/// outside it. The margins are right when every inner line is visible and every outer line is not.
///
/// The rest of the page shows the MomentoBooth [logoSvg] and what was printed on what: [printer], its media as
/// [mediaLabel], the margins the printer driver reported for the page ([driverMargins], when known) and [printedAt].
/// It is split in two blocks beside the rulers through the middle of the page, within the set margins.
Future<Uint8List> renderCalibrationPdf({
  required PrinterNodeData printer,
  required String mediaLabel,
  required double rulerLength,
  required PrintMargins margins,
  PrintMargins? driverMargins,
  String? logoSvg,
  required DateTime printedAt,
}) {
  const mm = PdfPageFormat.mm;
  final media = printer.media;
  final format = PdfPageFormat(media.widthMm * mm, media.heightMm * mm);
  final width = format.width, height = format.height;
  final rulerMarks = math.min(rulerLength, math.min(media.widthMm, media.heightMm) / 2).floor();

  String formatMm(double value) => value.toStringAsFixed(1);
  String marginsText(PrintMargins margins) =>
      'top ${formatMm(margins.top)}, right ${formatMm(margins.right)}, bottom ${formatMm(margins.bottom)}, left ${formatMm(margins.left)} mm';

  // The text grows with the media, from its size on 4 x 6 in media up to twice that on A4.
  final scale = (math.min(media.widthMm, media.heightMm) / 105).clamp(1.0, 2.0);
  final textStyle = pw.TextStyle(fontSize: 9 * scale, color: _dark);
  final headingStyle = pw.TextStyle(fontSize: 11 * scale, color: _pink, fontWeight: pw.FontWeight.bold);
  pw.Widget text(String text, [pw.TextStyle? style]) => pw.Text(text, style: style ?? textStyle, textAlign: pw.TextAlign.center);
  pw.Widget space(double heightMm) => pw.SizedBox(height: heightMm * scale * mm);

  final topBlock = <pw.Widget>[
    if (logoSvg != null) ...[pw.SvgImage(svg: logoSvg, width: 70 * scale * mm), space(4)],
    text('Calibration page', pw.TextStyle(fontSize: 16 * scale, color: _dark, fontWeight: pw.FontWeight.bold)),
    space(2),
    if (printer.label.isNotEmpty) text(printer.label, textStyle.copyWith(fontWeight: pw.FontWeight.bold)),
    text('${printer.backend == PrinterBackend.cups ? 'CUPS queue' : 'Printer'} ${printer.queueId}'),
    text('Media $mediaLabel, ${formatMm(media.widthMm)} x ${formatMm(media.heightMm)} mm'),
    text(printer.borderless ? 'Borderless' : 'With a border'),
  ];

  final bottomBlock = <pw.Widget>[
    text('Measure', headingStyle),
    text('On every side, the first ruler mark you can see is the margin of that side.'),
    if (driverMargins != null) text('The driver reports: ${marginsText(driverMargins)}'),
    space(2),
    text('Check', headingStyle),
    text('The pink line is on the set margins: ${marginsText(margins)}'),
    text(
      'They are right to within ${formatMm(calibrationControlDistance)} mm when, on every side, the inner dashed line is '
      'visible and the outer one is not.',
    ),
    space(2),
    text('Printed ${_formatDateTime(printedAt)}', pw.TextStyle(fontSize: 7 * scale, color: _grey)),
  ];

  final doc = pw.Document(title: "MomentoBooth calibration page")
    ..addPage(pw.Page(
      pageFormat: format,
      build: (_) => pw.SizedBox(
        width: width,
        height: height,
        child: pw.Stack(
          children: [
            pw.Positioned.fill(
              child: pw.CustomPaint(painter: (canvas, size) => _paintRulersAndLines(canvas, size, rulerMarks, margins)),
            ),
            ..._rulerLabels(width, height, rulerMarks),
            for (final (rect, children) in _contentBlocks(width, height, rulerMarks, margins, topBlock, bottomBlock))
              pw.Positioned(
                left: rect.left,
                top: rect.top,
                child: pw.SizedBox(
                  width: rect.width,
                  height: rect.height,
                  child: pw.FittedBox(
                    fit: pw.BoxFit.scaleDown,
                    child: pw.SizedBox(
                      width: rect.width,
                      child: pw.Column(mainAxisSize: pw.MainAxisSize.min, children: children),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    ));
  return doc.save();
}

/// Paints the frame on the edge of the page, the rulers on their bands, and the line on the set [margins] with its
/// control lines. PDF coordinates start at the bottom left.
void _paintRulersAndLines(PdfGraphics canvas, PdfPoint size, int rulerMarks, PrintMargins margins) {
  const mm = PdfPageFormat.mm;
  const bandWidth = 5 * mm;
  final cx = size.x / 2, cy = size.y / 2;
  final rulerEnd = rulerMarks * mm;
  double markLength(int mark) => (mark % 10 == 0 ? 4 : mark % 5 == 0 ? 3 : 2) * mm;

  // The bands behind the rulers make the edge where the printer cut easy to see.
  canvas
    ..setFillColor(_rulerBand)
    ..drawRect(0, cy, rulerEnd, bandWidth)
    ..drawRect(size.x - rulerEnd, cy, rulerEnd, bandWidth)
    ..drawRect(cx, 0, bandWidth, rulerEnd)
    ..drawRect(cx, size.y - rulerEnd, bandWidth, rulerEnd)
    ..fillPath()
    ..setStrokeColor(_dark)
    ..setLineWidth(0.3)
    ..drawRect(0, 0, size.x, size.y)
    ..drawLine(0, cy, rulerEnd, cy)
    ..drawLine(size.x, cy, size.x - rulerEnd, cy)
    ..drawLine(cx, 0, cx, rulerEnd)
    ..drawLine(cx, size.y, cx, size.y - rulerEnd);
  for (int mark = 1; mark <= rulerMarks; mark++) {
    final d = mark * mm, length = markLength(mark);
    canvas
      ..drawLine(d, cy, d, cy + length)
      ..drawLine(size.x - d, cy, size.x - d, cy + length)
      ..drawLine(cx, d, cx + length, d)
      ..drawLine(cx, size.y - d, cx + length, size.y - d);
  }
  canvas.strokePath();

  // The set margins, and the control lines inside and outside them. An outer line beyond the page is left out by the
  // page itself.
  void marginsRect(double offset) {
    final left = (margins.left + offset) * mm, right = (margins.right + offset) * mm;
    final top = (margins.top + offset) * mm, bottom = (margins.bottom + offset) * mm;
    canvas.drawRect(left, bottom, size.x - left - right, size.y - top - bottom);
  }

  canvas
    ..setStrokeColor(_pink)
    ..setLineWidth(0.6);
  marginsRect(0);
  canvas
    ..strokePath()
    ..setStrokeColor(_dark)
    ..setLineWidth(0.3)
    ..setLineDashPattern([1.5, 1.5]);
  marginsRect(calibrationControlDistance);
  marginsRect(-calibrationControlDistance);
  canvas
    ..strokePath()
    ..setLineDashPattern();
}

/// The numbers at every 5 mm of the rulers. Those of the rulers from the left and right edges are below them, as
/// their marks point up. Those of the rulers from the top and bottom edges are to the right of them, as their marks
/// point right.
List<pw.Widget> _rulerLabels(double width, double height, int rulerMarks) {
  const mm = PdfPageFormat.mm;
  final style = pw.TextStyle(fontSize: 7, color: _pink, fontWeight: pw.FontWeight.bold);
  pw.Widget label(int mark, {required double left, required double top, required pw.Alignment alignment}) => pw.Positioned(
    left: left,
    top: top,
    child: pw.SizedBox(width: 8 * mm, height: 3.5 * mm, child: pw.Align(alignment: alignment, child: pw.Text('$mark', style: style))),
  );

  return [
    for (int mark = 5; mark <= rulerMarks; mark += 5) ...[
      label(mark, left: mark * mm - 4 * mm, top: height / 2 + 0.5 * mm, alignment: pw.Alignment.topCenter),
      label(mark, left: width - mark * mm - 4 * mm, top: height / 2 + 0.5 * mm, alignment: pw.Alignment.topCenter),
      label(mark, left: width / 2 + 5.5 * mm, top: mark * mm - 1.75 * mm, alignment: pw.Alignment.centerLeft),
      label(mark, left: width / 2 + 5.5 * mm, top: height - mark * mm - 1.75 * mm, alignment: pw.Alignment.centerLeft),
    ],
  ];
}

/// Where the two blocks of content go, in points: within the set [margins] and beside the rulers through the middle
/// of the page. On portrait media, [first] goes above the rulers from the left and right edges and [second] below
/// them; on landscape media, [first] goes left of the rulers from the top and bottom edges and [second] right of them.
List<(({double left, double top, double width, double height}), List<pw.Widget>)> _contentBlocks(
  double width,
  double height,
  int rulerMarks,
  PrintMargins margins,
  List<pw.Widget> first,
  List<pw.Widget> second,
) {
  const mm = PdfPageFormat.mm;
  // The space the content keeps from the margins, from the end of the rulers, and from the rulers through the middle
  // (their bands and numbers).
  const padding = 2 * mm, rulerClearance = 3 * mm, middleBefore = 7 * mm, middleAfter = 6 * mm;
  final ruler = rulerMarks * mm;
  final left = margins.left * mm + padding, right = width - margins.right * mm - padding;
  final top = margins.top * mm + padding, bottom = height - margins.bottom * mm - padding;

  ({double left, double top, double width, double height}) rect(double l, double t, double r, double b) =>
      (left: l, top: t, width: math.max(r - l, 1), height: math.max(b - t, 1));

  if (width <= height) {
    final firstTop = math.max(top, ruler + rulerClearance), secondBottom = math.min(bottom, height - ruler - rulerClearance);
    return [
      (rect(left, firstTop, right, height / 2 - middleBefore), first),
      (rect(left, height / 2 + middleAfter, right, secondBottom), second),
    ];
  } else {
    final firstLeft = math.max(left, ruler + rulerClearance), secondRight = math.min(right, width - ruler - rulerClearance);
    return [
      (rect(firstLeft, top, width / 2 - padding, bottom), first),
      (rect(width / 2 + 5.5 * mm + 6 * mm, top, secondRight, bottom), second),
    ];
  }
}

String _formatDateTime(DateTime time) {
  String two(int value) => value.toString().padLeft(2, '0');
  return '${time.year}-${two(time.month)}-${two(time.day)} ${two(time.hour)}:${two(time.minute)}';
}
