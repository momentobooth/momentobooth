import 'dart:async';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/cupertino.dart';
import 'package:momento_booth/main.dart';
import 'package:momento_booth/managers/live_view_manager.dart';
import 'package:momento_booth/src/rust/api/printing.dart';
import 'package:momento_booth/src/rust/models/receipt_printing.dart';
import 'package:momento_booth/views/base/screen_controller_base.dart';
import 'package:momento_booth/views/components/imaging/quote_collage.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/post_recording_screen/post_recording_screen_view_model.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/start_screen/start_screen.dart';

class PostRecordingScreenController extends ScreenControllerBase<PostRecordingScreenViewModel> {

  AutoSizeGroup actionButtonGroup = AutoSizeGroup(), navigationButtonGroup = AutoSizeGroup();
  GlobalKey<QuoteCollageState> collageKey = GlobalKey();
  bool printSent = false;
  bool continueAfterPrint = false;

  // Initialization/Deinitialization

  PostRecordingScreenController({
    required super.viewModel,
    required super.contextAccessor,
  }) {
    getIt<LiveViewManager>().isRecordingLayout = false;
    Future.delayed(Duration(seconds: 2), screenshotAndPrint);
  }

  void onClickNext() {
    if (printSent) {
      router.go(StartScreen.defaultRoute);
    } else {
      continueAfterPrint = true;
      // Fallback for if printer does not work
      Future.delayed(Duration(seconds: 5), () {
        if (!printSent) {
          logWarning("Fallback navigation triggered");
          router.go(StartScreen.defaultRoute);
        }
      });
    }
  }

  Future<void> screenshotAndPrint() async {
    logInfo("Screenshotting and printing");
    final screenshot = await collageKey.currentState!.getCollageImage();
    unawaited(printReceipt(
      receipt: Receipt(
        commands: [
          ReceiptPrinterCommand.printImage(screenshot!.buffer.asUint8List()),
          ReceiptPrinterCommand.feed(),
          // ReceiptPrinterCommand.cut(),
        ],
      ),
      printerUsbVid: 0x0AA7,
      printerUsbPid: 0x0304,
      printingWidth: 576,
    ));
    printSent = true;
    if (continueAfterPrint) {
      onClickNext();
    }
  }

}
