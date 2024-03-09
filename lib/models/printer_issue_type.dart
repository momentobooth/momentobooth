import 'package:fluent_ui/fluent_ui.dart';
import 'package:momento_booth/app_localizations.dart';

enum PrinterIssueType {

  noInk,
  noMedia,
  mediaJam,
  connectionError,
  other;

  String getTitle(BuildContext context) {
    AppLocalizations localizations = AppLocalizations.of(context)!;
    return switch (this) {
      PrinterIssueType.noInk => localizations.printerErrorNoInkTitle,
      PrinterIssueType.noMedia => localizations.printerErrorNoMediaTitle,
      PrinterIssueType.mediaJam => localizations.printerErrorMediaJamTitle,
      PrinterIssueType.connectionError => localizations.printerErrorConnectionErrorTitle,
      PrinterIssueType.other => localizations.printerErrorUnknownIssueTitle,
    };
  }

  String getBody1(BuildContext context, String printerName, String errorText) {
    AppLocalizations localizations = AppLocalizations.of(context)!;
    return switch (this) {
      PrinterIssueType.noInk => localizations.printerErrorNoInkBody1(printerName),
      PrinterIssueType.noMedia => localizations.printerErrorNoMediaBody1(printerName),
      PrinterIssueType.mediaJam => localizations.printerErrorMediaJamBody1(printerName),
      PrinterIssueType.connectionError => localizations.printerErrorConnectionErrorBody1(printerName),
      PrinterIssueType.other => localizations.printerErrorUnknownIssueBody1(printerName, errorText),
    };
  }

  String getBody2(BuildContext context) {
    AppLocalizations localizations = AppLocalizations.of(context)!;
    return switch (this) {
      PrinterIssueType.noInk => localizations.printerErrorNoInkBody2,
      PrinterIssueType.noMedia => localizations.printerErrorNoMediaBody2,
      PrinterIssueType.mediaJam => localizations.printerErrorMediaJamBody2,
      PrinterIssueType.connectionError => localizations.printerErrorConnectionErrorBody2,
      PrinterIssueType.other => localizations.printerErrorUnknownIssueBody2,
    };
  }  

}
