
import 'dart:typed_data';

import 'package:mobx/mobx.dart';
import 'package:momento_booth/hardware_control/printing/cups_client.dart';
import 'package:momento_booth/hardware_control/printing/flutter_printing_client.dart';
import 'package:momento_booth/hardware_control/printing/printing_system_client.dart';
import 'package:momento_booth/managers/settings_manager.dart';
import 'package:momento_booth/models/settings.dart';

part 'printing_manager.g.dart';

class PrintingManager extends _PrintingManagerBase with _$PrintingManager {

  static final PrintingManager instance = PrintingManager._internal();

  PrintingManager._internal();

}

abstract class _PrintingManagerBase with Store {

  // ////////////// //
  // Initialization //
  // ////////////// //

  void initialize() {
    autorun((_) {
      // To make sure mobx detects that we are responding to changes to this property
      SettingsManager.instance.settings.hardware.printingImplementation;
      _updateConfig();
    });
  }


  // ///////// //
  // Reactions //
  // ///////// //

  @readonly
  PrintingSystemClient? _printingImplementation;

  void _updateConfig() {
    PrintingImplementation printingImplementationSetting = SettingsManager.instance.settings.hardware.printingImplementation;
    if (_printingImplementation == null && printingImplementationSetting == PrintingImplementation.none) return;
    if (_printingImplementation is FlutterPrintingClient && printingImplementationSetting == PrintingImplementation.flutterPrinting) return;
    if (_printingImplementation is CupsClient && printingImplementationSetting == PrintingImplementation.cups) return;

    _printingImplementation = switch (printingImplementationSetting) {
      PrintingImplementation.none => null,
      PrintingImplementation.flutterPrinting => FlutterPrintingClient(),
      PrintingImplementation.cups => CupsClient(),
    };
  }

  Future<void> printPdf(String taskName, Uint8List pdfData, {int copies=1, PrintSize printSize = PrintSize.normal}) async {
    await _printingImplementation!.printPdf(taskName, pdfData, copies: copies, printSize: printSize);
  }

}
