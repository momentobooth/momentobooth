import 'dart:math' as math;
import 'dart:typed_data';

import 'package:momento_booth/models/print_routing_graph.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// The ruler length the calibration dialog starts with, in mm.
const double defaultCalibrationRulerLength = 25;

/// Renders a calibration page on the media of [printer], to measure its margins: the part of the page that does not
/// end up visible on the print, because the printer cuts it off (borderless media) or cannot print there.
///
/// The page has a frame on its edge, and a ruler of [rulerLength] mm from the middle of every edge inwards, with a
/// mark every mm. The first mark that is visible on a side is the margin of that side. The rulers are shortened to
/// half the page when they do not fit.
///
/// The rest of the page shows the MomentoBooth [logoSvg] and what was printed on what: [printer], its media as
/// [mediaLabel], the margins the printer driver reported for the page ([driverMargins], when known) and [printedAt].
Future<Uint8List> renderCalibrationPdf({
  required PrinterNodeData printer,
  required String mediaLabel,
  required double rulerLength,
  PrintMargins? driverMargins,
  String? logoSvg,
  required DateTime printedAt,
}) {
  const mm = PdfPageFormat.mm;
  final format = PdfPageFormat(printer.media.widthMm * mm, printer.media.heightMm * mm);
  final width = format.width, height = format.height;
  final rulerMarks = math.min(rulerLength, math.min(printer.media.widthMm, printer.media.heightMm) / 2).floor();
  const labelStyle = pw.TextStyle(fontSize: 5);

  double markLength(int mark) => (mark % 10 == 0 ? 4 : mark % 5 == 0 ? 3 : 2) * mm;

  // The content stays clear of the rulers.
  final inset = math.min(rulerMarks + 3.0, math.min(printer.media.widthMm, printer.media.heightMm) / 2 - 1) * mm;
  String formatMm(double value) => value.toStringAsFixed(1);
  final media = printer.media;
  final driverMarginsLine = switch (driverMargins) {
    null => null,
    PrintMargins(:final top, :final right, :final bottom, :final left) =>
      'Margins reported by the driver: top ${formatMm(top)}, right ${formatMm(right)}, bottom ${formatMm(bottom)}, left ${formatMm(left)} mm',
  };

  final doc = pw.Document(title: "MomentoBooth calibration page")
    ..addPage(pw.Page(
      pageFormat: format,
      build: (_) => pw.SizedBox(
        width: width,
        height: height,
        child: pw.Stack(
          children: [
            pw.Positioned.fill(
              child: pw.CustomPaint(
                painter: (canvas, size) {
                  // PDF coordinates start at the bottom left.
                  final cx = size.x / 2, cy = size.y / 2;
                  canvas
                    ..setStrokeColor(PdfColors.black)
                    ..setLineWidth(0.3)
                    ..drawRect(0, 0, size.x, size.y)
                    ..drawLine(0, cy, rulerMarks * mm, cy)
                    ..drawLine(size.x, cy, size.x - rulerMarks * mm, cy)
                    ..drawLine(cx, 0, cx, rulerMarks * mm)
                    ..drawLine(cx, size.y, cx, size.y - rulerMarks * mm);
                  for (int mark = 1; mark <= rulerMarks; mark++) {
                    final d = mark * mm, length = markLength(mark);
                    canvas
                      ..drawLine(d, cy, d, cy + length)
                      ..drawLine(size.x - d, cy, size.x - d, cy + length)
                      ..drawLine(cx, d, cx + length, d)
                      ..drawLine(cx, size.y - d, cx + length, size.y - d);
                  }
                  canvas.strokePath();
                },
              ),
            ),
            for (int mark = 5; mark <= rulerMarks; mark += 5) ...[
              // The marks of the rulers from the left and right edges point up, and their numbers are below them. Those
              // of the rulers from the top and bottom edges point right, and their numbers are beyond them.
              pw.Positioned(left: mark * mm - 2, top: height / 2 + 1, child: pw.Text('$mark', style: labelStyle)),
              pw.Positioned(left: width - mark * mm - 2, top: height / 2 + 1, child: pw.Text('$mark', style: labelStyle)),
              pw.Positioned(left: width / 2 + 4.5 * mm, top: mark * mm - 2.5, child: pw.Text('$mark', style: labelStyle)),
              pw.Positioned(left: width / 2 + 4.5 * mm, top: height - mark * mm - 2.5, child: pw.Text('$mark', style: labelStyle)),
            ],
            pw.Positioned(
              left: inset,
              top: inset,
              child: pw.SizedBox(
                width: math.max(width - 2 * inset, 1),
                height: math.max(height - 2 * inset, 1),
                child: pw.Center(
                  child: pw.FittedBox(
                    fit: pw.BoxFit.scaleDown,
                    child: pw.Column(
                      mainAxisSize: pw.MainAxisSize.min,
                      children: [
                        if (logoSvg != null) pw.SvgImage(svg: _logoOnPaper(logoSvg), width: 50 * mm),
                        pw.SizedBox(height: 4 * mm),
                        pw.Text('Calibration page', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 2 * mm),
                        for (final line in [
                          if (printer.label.isNotEmpty) printer.label,
                          '${printer.backend == PrinterBackend.cups ? 'CUPS queue' : 'Printer'} ${printer.queueId}',
                          'Media $mediaLabel, ${formatMm(media.widthMm)} x ${formatMm(media.heightMm)} mm${printer.borderless ? ', borderless' : ''}',
                          ?driverMarginsLine,
                          'Printed ${_formatDateTime(printedAt)}',
                        ])
                          pw.Text(line, style: const pw.TextStyle(fontSize: 7)),
                        pw.SizedBox(height: 3 * mm),
                        pw.Text(
                          'On every side, the first ruler mark you can see is the margin of that side.',
                          style: pw.TextStyle(fontSize: 7, fontStyle: pw.FontStyle.italic),
                        ),
                      ],
                    ),
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

/// The logo is white, for the dark screens of the app. On paper it is printed black, with its colours set on its
/// shapes, as the PDF renderer does not apply the style sheet of the SVG.
String _logoOnPaper(String svg) => svg
    .replaceAll(RegExp('<defs>.*?</defs>', dotAll: true), '')
    .replaceAll('class="cls-1"', 'fill="#000000"')
    .replaceAll('class="cls-2"', 'fill="none" stroke="#000000" stroke-linejoin="round"');

String _formatDateTime(DateTime time) {
  String two(int value) => value.toString().padLeft(2, '0');
  return '${time.year}-${two(time.month)}-${two(time.day)} ${two(time.hour)}:${two(time.minute)}';
}
