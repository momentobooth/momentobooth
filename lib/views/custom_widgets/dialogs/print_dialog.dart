import 'package:fluent_ui/fluent_ui.dart' hide Colors, Slider;
import 'package:flutter/material.dart';
import 'package:momento_booth/app_localizations.dart';
import 'package:momento_booth/managers/settings_manager.dart';
import 'package:momento_booth/models/settings.dart';
import 'package:momento_booth/views/custom_widgets/buttons/photo_booth_filled_button.dart';
import 'package:momento_booth/views/custom_widgets/buttons/photo_booth_outlined_button.dart';
import 'package:momento_booth/views/custom_widgets/dialogs/modal_dialog.dart';

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

class _PrintDialogState extends State<PrintDialog> {
  int numPrints = 1;
  PrintSize printSize = PrintSize.normal;

  int get gridX => switch(printSize) {
    PrintSize.small => SettingsManager.instance.settings.hardware.printLayoutSettings.gridSmall.x,
    PrintSize.tiny => SettingsManager.instance.settings.hardware.printLayoutSettings.gridTiny.x,
    _ => 1,
  };

  int get gridY => switch(printSize) {
    PrintSize.small => SettingsManager.instance.settings.hardware.printLayoutSettings.gridSmall.y,
    PrintSize.tiny => SettingsManager.instance.settings.hardware.printLayoutSettings.gridTiny.y,
    _ => 1,
  };

  @override
  Widget build(BuildContext context) {
    AppLocalizations localizations = AppLocalizations.of(context)!;

    const textStyle = TextStyle(fontWeight: FontWeight.w500, fontSize: 18, height: 1);

    return ModalDialog(
      title: localizations.genericPrintButton,
      body: Column(
        children: [
          Row(
            children: [
              const Text(
                "Size: ",
                style: textStyle,
              ),
              const SizedBox(width: 12,),
              PrintSizeChoice(printSize: printSize, onChanged: (value) => {
                setState(() {
                  printSize = value;
                })
              })
            ],
          ),
          const SizedBox(height: 16.0),
          const Text(
            "Number of prints:",
            textAlign: TextAlign.left,
            style: textStyle,
          ),
          Text(
            "$numPrints prints → ${numPrints * gridX * gridY} printed images",
            textAlign: TextAlign.left,
          ),
          const SizedBox(height: 16.0),
          Material(
            color: Colors.transparent,
            child: Slider(
              value: numPrints.toDouble(),
              min: 1,
              max: widget.maxPrints.toDouble(),
              divisions: widget.maxPrints-1,
              label: numPrints.toString(),
              onChanged: (value) {
                setState(() {
                  numPrints = value.round();
                });
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
          icon: FluentIcons.print,
          onPressed: () => widget.onPrintPressed(printSize, numPrints),
        ),
      ],
      dialogType: ModalDialogType.input,
    );
  }
}

class PrintSizeChoice extends StatelessWidget {
  const PrintSizeChoice({super.key, required this.printSize, required this.onChanged});
  final PrintSize printSize;
  final ValueChanged<PrintSize> onChanged;

  @override
  Widget build(BuildContext context) {
    // ButtonStyle style = ButtonStyle(foregroundColor: MaterialStateProperty.all(Colors.white));
    final settings = SettingsManager.instance.settings.hardware.printLayoutSettings;
    return SegmentedButton<PrintSize>(
      // style: style,
      segments: <ButtonSegment<PrintSize>>[
        const ButtonSegment<PrintSize>(
            value: PrintSize.normal,
            label: Text('Normal'),
            icon: Icon(Icons.looks_one_outlined)),
        if (settings.mediaSizeSmall.mediaSizeString.isNotEmpty)
        const ButtonSegment<PrintSize>(
            value: PrintSize.small,
            label: Text('Small'),
            icon: Icon(Icons.looks_two_outlined)),
        if (settings.mediaSizeTiny.mediaSizeString.isNotEmpty)
        const ButtonSegment<PrintSize>(
            value: PrintSize.tiny,
            label: Text('Tiny'),
            icon: Icon(Icons.looks_3_outlined)),
      ],
      selected: <PrintSize>{printSize},
      onSelectionChanged: (newSelection) {
        // By default there is only a single segment that can be
        // selected at one time, so its value is always the first
        // item in the selected set.
        onChanged(newSelection.first);
      },
    );
  }
}
