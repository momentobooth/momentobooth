import 'dart:ffi';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:momento_booth/exceptions/win32_exception.dart';
import 'package:momento_booth/main.dart';
import 'package:momento_booth/managers/settings_manager.dart';
import 'package:momento_booth/utils/logger.dart';
import 'package:momento_booth/models/settings.dart';
import 'package:momento_booth/utils/file_utils.dart';
import 'package:path/path.dart' as path;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:win32/win32.dart';

Future<Uint8List> getImagePDF(Uint8List imageData) async {
  late final pw.MemoryImage image = pw.MemoryImage(imageData);
  const mm = PdfPageFormat.mm;
  final settings = SettingsManager.instance.settings.hardware;

  final pageFormat = settings.printingImplementation == PrintingImplementation.cups ?
    PdfPageFormat(settings.printLayoutSettings.mediaSizeNormal.mediaSizeHeight * mm, settings.printLayoutSettings.mediaSizeNormal.mediaSizeWidth * mm,
                  marginBottom: settings.printerMarginBottom * mm,
                  marginLeft: settings.printerMarginLeft * mm,
                  marginRight: 0,
                  marginTop: settings.printerMarginTop * mm)
    : PdfPageFormat(settings.pageWidth * mm, settings.pageHeight * mm,
                  marginBottom: settings.printerMarginBottom * mm,
                  marginLeft: settings.printerMarginLeft * mm,
                  marginRight: settings.printerMarginRight * mm,
                  marginTop: settings.printerMarginTop * mm,);
  const fit = pw.BoxFit.contain;

  // Check if photo should be rotated
  // Do not assume any prior knowledge about the image.
  final bool correctImgRotation = image.width! > image.height!;
  late final pw.Image imageWidget;
  imageWidget = correctImgRotation
      ? pw.Image(image, fit: fit, height: pageFormat.availableWidth, width: pageFormat.availableHeight)
      : pw.Image(image, fit: fit, height: pageFormat.availableHeight, width: pageFormat.availableWidth);

  final doc = pw.Document(title: "MomentoBooth image")
    ..addPage(pw.Page(
      pageFormat: pageFormat,
      build: (context) {
        return pw.Center(
          child: correctImgRotation ? pw.Transform.rotateBox(angle: 0.5 * pi, child: imageWidget) : imageWidget,
        );
      },
    ));

  return await doc.save();  
}

Future<Uint8List> getSplitImagePDF(Uint8List imageData) async {
  late final pw.MemoryImage image = pw.MemoryImage(imageData);
  const mm = PdfPageFormat.mm;
  final settings = SettingsManager.instance.settings.hardware.printLayoutSettings;
  final hSettings = SettingsManager.instance.settings.hardware;
  final pageFormats = [
    PdfPageFormat(settings.mediaSizeSplit.mediaSizeHeight * mm, settings.mediaSizeSplit.mediaSizeWidth * mm,
                  marginBottom: hSettings.printerMarginBottom * mm,
                  marginLeft: hSettings.printerMarginLeft * mm,
                  marginRight: 0,
                  marginTop: hSettings.printerMarginTop * mm),
    PdfPageFormat(settings.mediaSizeSplit.mediaSizeHeight * mm, settings.mediaSizeSplit.mediaSizeWidth * mm,
                  marginBottom: hSettings.printerMarginBottom * mm,
                  marginLeft: 0,
                  marginRight: hSettings.printerMarginRight * mm,
                  marginTop: hSettings.printerMarginTop * mm),
  ];
  const fit = pw.BoxFit.fitHeight;

  final imageWidgets = [
    pw.Image(image, fit: fit, height: pageFormats[0].availableHeight, width: pageFormats[0].availableWidth, alignment: pw.Alignment.centerLeft),
    pw.Image(image, fit: fit, height: pageFormats[1].availableHeight, width: pageFormats[1].availableWidth, alignment: pw.Alignment.centerRight),
  ];

  final doc = pw.Document(title: "MomentoBooth image");
  for (int i = 0; i < 2; i++){
    doc.addPage(pw.Page(
      pageFormat: pageFormats[i],
      build: (_) => pw.Center(child: imageWidgets[i]),
    ));
  }

  return await doc.save();  
}

Future<Uint8List> getImagePdfWithPageSize(Uint8List imageData, PrintSize printSize) async {
  const mm = PdfPageFormat.mm;
  final settings = SettingsManager.instance.settings.hardware.printLayoutSettings;
  final hSettings = SettingsManager.instance.settings.hardware;

  late final Uint8List pdfData;
  switch(printSize) {
    case PrintSize.normal:
      pdfData = await getImagePDF(imageData);
    case PrintSize.split:
      pdfData = await getSplitImagePDF(imageData);
    case PrintSize.small:
      final pageFormat = PdfPageFormat(settings.mediaSizeSmall.mediaSizeHeight * mm, settings.mediaSizeSmall.mediaSizeWidth * mm,
                                    marginBottom: hSettings.printerMarginBottom * mm,
                                    marginLeft: hSettings.printerMarginLeft * mm,
                                    marginRight: hSettings.printerMarginRight * mm,
                                    marginTop: hSettings.printerMarginTop * mm,);
      pdfData = await getImageGridPDF(imageData, settings.gridSmall.x, settings.gridSmall.y, settings.gridSmall.rotate, pageFormat);
    case PrintSize.tiny:
      final pageFormat = PdfPageFormat(settings.mediaSizeTiny.mediaSizeHeight * mm, settings.mediaSizeTiny.mediaSizeWidth * mm,
                                    marginBottom: hSettings.printerMarginBottom * mm,
                                    marginLeft: hSettings.printerMarginLeft * mm,
                                    marginRight: hSettings.printerMarginRight * mm,
                                    marginTop: hSettings.printerMarginTop * mm,);
      pdfData = await getImageGridPDF(imageData, settings.gridTiny.x, settings.gridTiny.y, settings.gridTiny.rotate, pageFormat);
  }
  
  Directory outputDir = Directory(SettingsManager.instance.settings.output.localFolder);
  final filePath = path.join(outputDir.path, 'latest-print.pdf');
  await writeBytesToFileLocked(filePath, pdfData);
  return pdfData;
}

Future<Uint8List> getImageGridPDF(Uint8List imageData, int x, int y, bool rotate, PdfPageFormat pageFormat) async {
  pw.MemoryImage image = pw.MemoryImage(imageData);
  const fit = pw.BoxFit.contain;

  // Check if photo should be rotated
  // Do not assume any prior knowledge about the image.
  final bool correctImgRotation = image.width! > image.height!;
  double cellHeight = pageFormat.availableHeight/y;
  double cellWidth = pageFormat.availableWidth/x;

  pw.Widget imageWidget = pw.Image(image, fit: fit, height: cellHeight, width: cellWidth);
  if (correctImgRotation ^ rotate) {
    imageWidget = pw.Transform.rotateBox(
      angle: 0.5 * pi,
      child: pw.Image(image, fit: fit, height: cellWidth, width: cellHeight));
  }

  final grid = pw.GridView(
    crossAxisCount: x,
    children: [
      for (int i = 0; i < x*y; i++)
      pw.Expanded(child: imageWidget)
    ],
  );

  final doc = pw.Document(title: "MomentoBooth image")
    ..addPage(pw.Page(
      pageFormat: pageFormat,
      build: (context) {
        return grid;
      },
    ));

  return await doc.save();
}

enum JobStatus {
  blocked(0x00000200),
  complete(0x00001000),
  deleted(0x00000100),
  deleting(0x00000004),
  error(0x00000002),
  offline(0x00000020),
  paperout(0x00000040),
  paused(0x00000001),
  printed(0x00000080),
  printing(0x00000010),
  restart(0x00000800),
  spooling(0x00000008),
  userIntervention(0x00000400),
  unknown(0x00000000);

  final int value;
  const JobStatus(this.value);
}

class JobInfo {
  DateTime submitted;
  List<JobStatus> status;
  int statusRaw;

  JobInfo(this.status, this.submitted, this.statusRaw);

  @override
  String toString() {
    final String statusString = status.map((e) => e.name).join(", ");
    return "Job {status: $statusString (${statusRaw.toHexString(32)}), submitted: ${submitted.toLocal()}}";
  }
}

class PrinterStatus {
  int jobs;
  bool hasError;
  bool paperOut;

  PrinterStatus(this.jobs, this.hasError, this.paperOut);
}

/// Get the status of all printers.
/// Returns list of statusses.
List<PrinterStatus> checkPrintersStatus(List<String> printerNames) {
  List<PrinterStatus> output = [];
  for (String printerName in printerNames) {
    bool hasError = false;
    bool paperOut = false;
    late final List<JobInfo> jobList;
    try {
      jobList = getJobList(printerName);
    } catch (e) {
      // If the function fails, then at least we can say there is _some_ error
      hasError = true;
      jobList = [];
      getIt<Logger>().logError(e);
    }
    // Check if there are prints that have errored
    hasError = hasError || jobList.fold(false, (previousValue, element) => previousValue || element.status.contains(JobStatus.error));
    paperOut = paperOut || jobList.fold(false, (previousValue, element) => previousValue || element.status.contains(JobStatus.paperout));
    output.add(PrinterStatus(jobList.length, hasError, paperOut));
  }
  return output;
}

List<JobInfo> getJobList(String printerName) {
  // Todo: eventually add OSx and Linux support
  if (!Platform.isWindows) return [];
  return using((alloc) {
    // Allocate necessary pointers
    Pointer<Utf16> printerNameHandle;
    Pointer<IntPtr> handle;
    Pointer<Uint8> jobs;
    Pointer<Uint32> usedBytes;
    Pointer<Uint32> numJobs;

    // Allocate space for printer name and set the string.
    printerNameHandle = printerName.toNativeUtf16();
    // Allocate other pointers
    handle = alloc<IntPtr>();
    const numBytes = 100000;
    jobs = alloc<Uint8>(numBytes);
    usedBytes = alloc<Uint32>();
    numJobs = alloc<Uint32>();

    // Get the printer handle.
    final bool openSuccess = OpenPrinter(printerNameHandle, handle, Pointer.fromAddress(0)) != 0;
    if (!openSuccess) throw Win32Exception.fromLastError("Error opening printer $printerName to acquire print jobs");

    final int printerHandleValue = handle.value;
    // Enumerate jobs for printer.
    const int returnType = 1; // JOB_INFO_1
    final bool enumSuccess = EnumJobs(printerHandleValue, 0, 100, returnType, jobs, numBytes, usedBytes, numJobs) != 0;
    if (!enumSuccess) throw Win32Exception.fromLastError("Error enumerating print jobs for printer $printerName");

    getIt<Logger>().logDebug("Printer $printerName (handle ${printerHandleValue.toHexString(32)}) has ${numJobs.value} jobs (object is ${usedBytes.value} bytes)");

    List<JobInfo> jobList = [];
    for (var i = 0; i < numJobs.value; i++) {
      var job = (jobs.cast<JOB_INFO_1>() + i).ref;
      // Convert job status
      var statusVal = job.Status;
      var statusString = job.pStatus.address != 0 ? job.pStatus.toDartString() : "";
      if (statusString.isNotEmpty) {
        getIt<Logger>().logDebug("Custom statusstring for printer $printerName: $statusString");
      }
      // Extract list of statusses
      final List<JobStatus> status = JobStatus.values.where((element) => element.value & statusVal > 0).toList();
      if (status.isEmpty) { status.add(JobStatus.unknown); }

      // Convert submitted time object
      final submitted = job.Submitted;
      var time = DateTime.utc(submitted.wYear, submitted.wMonth, submitted.wDay, submitted.wHour, submitted.wMinute, submitted.wSecond, submitted.wMilliseconds);

      // Save jobinfo to list
      jobList.add(JobInfo(status, time, statusVal));
    }

    // Close printer again so we can actually print...
    final bool closeSuccess = ClosePrinter(printerHandleValue) != 0;
    if (!closeSuccess) throw Win32Exception.fromLastError("Error closing printer $printerName");
    return jobList;
  });
}
