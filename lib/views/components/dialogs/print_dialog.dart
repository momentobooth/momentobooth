import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:momento_booth/app_localizations.dart';
import 'package:momento_booth/main.dart';
import 'package:momento_booth/managers/settings_manager.dart';
import 'package:momento_booth/models/settings.dart';
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

class _PrintDialogState extends State<PrintDialog> {

  int numPrints = 1;
  PrintSize printSize = PrintSize.normal;

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
