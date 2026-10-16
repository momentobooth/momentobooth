import 'package:fluent_ui/fluent_ui.dart' show Colors, FluentTheme;
import 'package:flutter/material.dart' hide Colors;
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:momento_booth/app_localizations.dart';
import 'package:momento_booth/main.dart';
import 'package:momento_booth/managers/printing_manager.dart';
import 'package:momento_booth/models/settings.dart';
import 'package:momento_booth/views/components/buttons/photo_booth_filled_button.dart';
import 'package:momento_booth/views/components/buttons/photo_booth_outlined_button.dart';
import 'package:momento_booth/views/components/dialogs/modal_dialog.dart';

class PrintDialog extends StatefulWidget {

  final VoidCallback onCancel;

  /// Called with the print size to print at, which is split instead of the chosen normal size for a collage of three
  /// photos (see [PrintingManagerBase.printSizeFor]).
  final void Function(PrintSize size, int copies) onPrintPressed;
  final int maxPrints;
  final bool isThreePhotoCollage;

  const PrintDialog({
    super.key,
    required this.onCancel,
    required this.onPrintPressed,
    this.maxPrints = 5,
    this.isThreePhotoCollage = false,
  });

  @override
  State<PrintDialog> createState() => _PrintDialogState();

}

class _PrintDialogState extends State<PrintDialog> {

  /// The print sizes users choose from. Split prints follow from the photo, so they are not a choice.
  static List<PrintSize> get _choices => [
    for (final size in [PrintSize.normal, PrintSize.small, PrintSize.tiny])
      if (getIt<PrintingManager>().printableSizes.contains(size)) size,
  ];

  int numPrints = 1;
  PrintSize printSize = _choices.firstOrNull ?? PrintSize.normal;

  @override
  Widget build(BuildContext context) {
    AppLocalizations localizations = AppLocalizations.of(context)!;
    final printing = getIt<PrintingManager>();
    final printedSize = printing.printSizeFor(printSize, isThreePhotoCollage: widget.isThreePhotoCollage);
    // Unknown when the routes of this print size produce a different number of physical copies.
    final copiesPerPrint = printing.copiesPerPrint(printSize, isThreePhotoCollage: widget.isThreePhotoCollage);
    // The slider shows what guests get, the physical copies, while it counts prints.
    final shownCopies = numPrints * (copiesPerPrint ?? 1);

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
                choices: _choices,
                printSize: printSize,
                onChanged: (value) {
                  setState(() => printSize = value);
                },
              ),
            ],
          ),
          const SizedBox(height: 16.0),
          Text(
            localizations.printDialogNumberOfPrints(shownCopies),
            textAlign: TextAlign.left,
            style: textStyle,
          ),
          if (copiesPerPrint != null)
            Text(
              localizations.printDialogCopiesPerSheet(copiesPerPrint),
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
              label: shownCopies.toString(),
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
          onPressed: () => widget.onPrintPressed(printedSize, numPrints),
        ),
      ],
      dialogType: ModalDialogType.input,
    );
  }

}

class PrintSizeChoice extends StatelessWidget {

  final List<PrintSize> choices;
  final PrintSize printSize;
  final ValueChanged<PrintSize> onChanged;

  const PrintSizeChoice({super.key, required this.choices, required this.printSize, required this.onChanged});

  @override
  Widget build(BuildContext context) {
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
        for (final size in choices)
          ButtonSegment<PrintSize>(
            value: size,
            label: Text(switch (size) {
              PrintSize.normal || PrintSize.split => 'Normal',
              PrintSize.small => 'Small',
              PrintSize.tiny => 'Tiny',
            }),
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
