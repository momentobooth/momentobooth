import 'dart:ffi';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:ffi/ffi.dart';
import 'package:loggy/loggy.dart';
import 'package:momento_booth/exceptions/win32_exception.dart';
import 'package:momento_booth/managers/settings_manager.dart';
import 'package:momento_booth/managers/stats_manager.dart';
import 'package:path/path.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:win32/win32.dart';

int lastUsedPrinterIndex = -1;
final loggy = Loggy<UiLoggy>("hardware utils");

Future<Uint8List> getImagePDF(Uint8List imageData) async {
  late final pw.MemoryImage image = pw.MemoryImage(imageData);
  const mm = PdfPageFormat.mm;
  final settings = SettingsManager.instance.settings.hardware;
  final pageFormat = PdfPageFormat(settings.pageWidth * mm, settings.pageHeight * mm,
                                    marginBottom: settings.printerMarginBottom * mm,
                                    marginLeft: settings.printerMarginLeft * mm,
                                    marginRight: settings.printerMarginRight * mm,
                                    marginTop: settings.printerMarginTop * mm,);
  const fit = pw.BoxFit.contain;

  // Check if photo should be rotated
  // Do not assume any prior knowledge about the image.
  final bool rotate = image.width! > image.height!;
  late final pw.Image imageWidget;
  imageWidget = rotate
      ? pw.Image(image, fit: fit, height: pageFormat.availableWidth, width: pageFormat.availableHeight)
      : pw.Image(image, fit: fit, height: pageFormat.availableHeight, width: pageFormat.availableWidth);

  final doc = pw.Document(title: "MomentoBooth image")
    ..addPage(pw.Page(
      pageFormat: pageFormat,
      build: (context) {
        return pw.Center(
          child: rotate ? pw.Transform.rotateBox(angle: 0.5 * pi, child: imageWidget) : imageWidget,
        );
      },
    ));

  return await doc.save();
}

Future<List<Printer>> getSelectedPrinters() async {
  // Find printer that was set in settings in available printers.
  final sourcePrinters = await Printing.listPrinters();
  List<Printer> printers = <Printer>[];

  for (String name in SettingsManager.instance.settings.hardware.printerNames) {
    Printer? selected = sourcePrinters.firstWhereOrNull((printer) => printer.name == name);
    if (selected == null) {
        loggy.error("Could not find selected printer ($name)");
    }
    printers.add(selected!);
  }
  return printers;
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
      loggy.error(e);
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

    loggy.debug("Printer $printerName (handle ${printerHandleValue.toHexString(32)}) has ${numJobs.value} jobs (object is ${usedBytes.value} bytes)");

    List<JobInfo> jobList = [];
    for (var i = 0; i < numJobs.value; i++) {
      var job = jobs.cast<JOB_INFO_1>().elementAt(i).ref;
      // Convert job status
      var statusVal = job.Status;
      var statusString = job.pStatus.address != 0 ? job.pStatus.toDartString() : "";
      if (statusString.isNotEmpty) {
        loggy.debug("Custom statusstring for printer $printerName: $statusString");
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

Future<bool> printPDF(Uint8List pdfData) async {
  final settings = SettingsManager.instance.settings.hardware;
  final printers = await getSelectedPrinters();
  if (printers.isEmpty) return false;

  if (++lastUsedPrinterIndex >= printers.length) { lastUsedPrinterIndex = 0; }
  final printer = printers[lastUsedPrinterIndex];

  loggy.debug("Printing with printer #${lastUsedPrinterIndex+1} (${printer.name})");

  try {
    final jobList = getJobList(printer.name);
    loggy.debug("Job list for printer ${printer.name} = $jobList");
  } catch (e) {
    loggy.error(e);
  }

  bool success = await Printing.directPrintPdf(
      printer: printer,
      name: "MomentoBooth image",
      onLayout: (pageFormat) => pdfData,
      usePrinterSettings: settings.usePrinterSettings,
  );
  StatsManager.instance.addPrintedPhoto();
  
  Directory outputDir = Directory(SettingsManager.instance.settings.output.localFolder);
  final filePath = join(outputDir.path, 'latest-print.pdf');
  File file = await File(filePath).create();
  await file.writeAsBytes(pdfData);

  return success;
}
