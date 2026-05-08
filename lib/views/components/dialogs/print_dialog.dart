import 'package:fluent_ui/fluent_ui.dart' show Colors, FluentTheme;
import 'package:flutter/material.dart' hide Colors;
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:momento_booth/app_localizations.dart';
import 'package:momento_booth/main.dart';
import 'package:momento_booth/managers/settings_manager.dart';
import 'package:momento_booth/models/app_action.dart';
import 'package:momento_booth/models/settings.dart';
import 'package:momento_booth/utils/speech_phrases.dart';
import 'package:momento_booth/views/base/has_actions_mixin.dart';
import 'package:momento_booth/views/components/buttons/photo_booth_filled_button.dart';
import 'package:momento_booth/views/components/buttons/photo_booth_outlined_button.dart';
import 'package:momento_booth/views/components/dialogs/modal_dialog.dart';

class PrintDialog extends StatefulWidget {

  final VoidCallback onCancel;
  final void Function(PrintSize size, int copies) onPrintPressed;
  final int maxPrints;

  const PrintDialog({
    super.key,
    required this.onCancel,
    required this.onPrintPressed,
    this.maxPrints = 5,
  });

  @override
  State<PrintDialog> createState() => _PrintDialogState();

}

class _PrintDialogState extends State<PrintDialog> with HasActionsMixin {

  int numPrints = 1;
  PrintSize printSize = PrintSize.normal;

  String get sizeEnumOptions => PrintSize.values.where((e) => e != PrintSize.split).map((e) => '"${e.name}"').join(", ");

  @override
  List<AppAction> get actions => [
    AppAction(
      name: "cancel",
      callback: (_, response) { widget.onCancel(); response(true, "Cancel button pressed"); },
      title: 'Cancel',
      description: 'Presses the cancel button in the print dialog.',
      examples: cancelPhrases
    ),
    AppAction(
      name: "set_copies",
      callback: setCopiesAPI,
      title: 'Set Copies',
      description: 'Sets the number of copies to print.',
      inputSchema: '{ "type": "object", "properties": { "copies": { "type": "integer", "description": "The number of copies to print", "minimum": 1, "maximum": ${widget.maxPrints} } }, "required": ["copies"], "additionalProperties": false }'
    ),
    AppAction(
      name: "set_size",
      callback: setSizeAPI,
      title: 'Set Size',
      description: 'Sets the print size.',
      inputSchema: '{ "type": "object", "properties": { "size": { "enum": [$sizeEnumOptions], "description": "The print size to set" } }, "required": ["size"], "additionalProperties": false }'
    ),
    AppAction(
      name: "print",
      callback: (_, response) { widget.onPrintPressed(printSize, numPrints); response(true, "Print button pressed, printing $numPrints copies of $printSize size"); },
      title: 'Print',
      description: 'Presses the print button in the print dialog.',
      examples: printPhrases
    ),
  ];

  void setSizeAPI(Map<String, dynamic> params, Function(bool, String) response) {
    final sizeStr = params["size"];
    if (sizeStr == null) {
      response(false, "Missing 'size' parameter");
      return;
    }
    if (sizeStr is! String) {
      response(false, "Invalid 'size' parameter: must be a string");
      return;
    }
    final size = PrintSize.values.firstWhere((e) => e.name == sizeStr, orElse: () => PrintSize.normal);
    setState(() => printSize = size);
    response(true, "Print size set to $sizeStr");
  }

  void setCopiesAPI(Map<String, dynamic> params, Function(bool, String) response) {
    final copiesParam = params["copies"];
    if (copiesParam == null) {
      response(false, "Missing 'copies' parameter");
      return;
    }
    if (copiesParam is! int) {
      response(false, "Invalid 'copies' parameter: must be an integer");
      return;
    }
    final copies = copiesParam.clamp(1, widget.maxPrints);
    setState(() => numPrints = copies);
    response(true, "Number of copies set to $copies");
  }

  @override
  void initState() {
    super.initState();
    pushActions();
  }

  @override
  void dispose() {
    popActions();
    super.dispose();
  }

  @override
  String get scopeName => "Print Dialog";

  int get gridX => switch (printSize) {
    PrintSize.small => getIt<SettingsManager>().settings.hardware.printLayoutSettings.gridSmall.x,
    PrintSize.tiny => getIt<SettingsManager>().settings.hardware.printLayoutSettings.gridTiny.x,
    _ => 1,
  };

  int get gridY => switch (printSize) {
    PrintSize.small => getIt<SettingsManager>().settings.hardware.printLayoutSettings.gridSmall.y,
    PrintSize.tiny => getIt<SettingsManager>().settings.hardware.printLayoutSettings.gridTiny.y,
    _ => 1,
  };

  @override
  Widget build(BuildContext context) {
    AppLocalizations localizations = AppLocalizations.of(context)!;

    const textStyle = TextStyle(fontWeight: FontWeight.w500, fontSize: 18, height: 1);

    return ModalDialog(
      title: localizations.printDialogTitle,
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(
                localizations.printDialogSizeSetting,
                style: textStyle,
              ),
              const SizedBox(width: 12),
              PrintSizeChoice(
                printSize: printSize,
                onChanged: (value) {
                  setState(() => printSize = value);
                },
              ),
            ],
          ),
          const SizedBox(height: 16.0),
          Text(
            localizations.printDialogNoOfPrintsSetting,
            textAlign: TextAlign.left,
            style: textStyle,
          ),
          Text(
            localizations.printDialogSummary(numPrints, numPrints * gridX * gridY),
            textAlign: TextAlign.left,
          ),
          const SizedBox(height: 16.0),
          Material(
            color: Colors.transparent,
            child: Slider(
              activeColor: FluentTheme.of(context).accentColor,
              value: numPrints.toDouble(),
              min: 1,
              max: widget.maxPrints.toDouble(),
              divisions: widget.maxPrints - 1,
              label: numPrints.toString(),
              onChanged: (value) {
                setState(() => numPrints = value.round());
              },
            ),
          ),
        ],
      ),
      actions: [
        PhotoBoothOutlinedButton(
          title: localizations.genericCancelButton,
          onPressed: widget.onCancel,
        ),
        PhotoBoothFilledButton(
          title: localizations.genericPrintButton,
          icon: LucideIcons.printer,
          onPressed: () => widget.onPrintPressed(printSize, numPrints),
        ),
      ],
      dialogType: ModalDialogType.input,
    );
  }

}

class PrintSizeChoice extends StatelessWidget {

  final PrintSize printSize;
  final ValueChanged<PrintSize> onChanged;

  const PrintSizeChoice({super.key, required this.printSize, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final settings = getIt<SettingsManager>().settings.hardware.printLayoutSettings;
    return SegmentedButton<PrintSize>(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith<Color>(
          (states) {
              if (states.contains(WidgetState.selected)) {
                return FluentTheme.of(context).accentColor;
              }
              return Colors.transparent;
            },
        ),
        iconColor: WidgetStateProperty.all(Colors.white)
      ),
      segments: [
        const ButtonSegment<PrintSize>(
          value: PrintSize.normal,
          label: Text('Normal'),
        ),
        if (settings.mediaSizeSmall.mediaSizeString.isNotEmpty)
          const ButtonSegment<PrintSize>(
            value: PrintSize.small,
            label: Text('Small'),
          ),
        if (settings.mediaSizeTiny.mediaSizeString.isNotEmpty)
          const ButtonSegment<PrintSize>(
            value: PrintSize.tiny,
            label: Text('Tiny'),
          ),
      ],
      selected: {printSize},
      onSelectionChanged: (newSelection) {
        // By default there is only a single segment that can be
        // selected at one time, so its value is always the first
        // item in the selected set.
        onChanged(newSelection.first);
      },
    );
  }

}
