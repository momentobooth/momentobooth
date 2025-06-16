
import 'dart:typed_data';

import 'package:mobx/mobx.dart';
import 'package:momento_booth/hardware_control/printing/cups_client.dart';
import 'package:momento_booth/hardware_control/printing/flutter_printing_client.dart';
import 'package:momento_booth/hardware_control/printing/printing_system_client.dart';
import 'package:momento_booth/main.dart';
import 'package:momento_booth/managers/settings_manager.dart';
import 'package:momento_booth/models/settings.dart';
import 'package:momento_booth/models/subsystem.dart';
import 'package:momento_booth/utils/logger.dart';

part 'printing_manager.g.dart';

class PrintingManager = PrintingManagerBase with _$PrintingManager;

abstract class PrintingManagerBase extends Subsystem with Store, Logger {

  // ////////////// //
  // Initialization //
  // ////////////// //

  @override
  Null initialize() {
    autorun((_) {
      // To make sure mobx detects that we are responding to changes to this property
      getIt<SettingsManager>().settings.hardware.printingImplementation;
      _updateConfig();
    });
  }

  // ///////// //
  // Reactions //
  // ///////// //

  @readonly
  PrintingSystemClient? _printingImplementation;

  void _updateConfig() {
    PrintingImplementation printingImplementationSetting = getIt<SettingsManager>().settings.hardware.printingImplementation;
    if (_printingImplementation == null && printingImplementationSetting == PrintingImplementation.none) return;
    if (_printingImplementation is FlutterPrintingClient && printingImplementationSetting == PrintingImplementation.flutterPrinting) return;
    if (_printingImplementation is CupsClient && printingImplementationSetting == PrintingImplementation.cups) return;

    switch (printingImplementationSetting) {
      case PrintingImplementation.none:
        _printingImplementation = null;
        reportSubsystemDisabled();
      case PrintingImplementation.flutterPrinting:
        _printingImplementation = FlutterPrintingClient();
        reportSubsystemOk();
      case PrintingImplementation.cups:
        _printingImplementation = CupsClient();
        reportSubsystemOk();
    }
  }

  Future<void> printPdf(String taskName, Uint8List pdfData, {int copies=1, PrintSize printSize = PrintSize.normal}) async {
    await _printingImplementation!.printPdf(taskName, pdfData, copies: copies, printSize: printSize);
  }

}
