import 'dart:math';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:momento_booth/views/components/buttons/photo_booth_filled_button.dart';
import 'package:momento_booth/views/components/buttons/photo_booth_outlined_button.dart';
import 'package:momento_booth/views/components/dialogs/modal_dialog.dart';

class EnterPinDialog extends StatefulWidget {

  const EnterPinDialog({super.key});

  @override
  State<EnterPinDialog> createState() => _EnterPinDialogState();
}

class _EnterPinDialogState extends State<EnterPinDialog> {

  String pincode = '';

  @override
  Widget build(BuildContext context) {
    return ModalDialog(
      title: 'Enter PIN',
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // PIN weergave
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              max(1, pincode.length),
              (i) => Container(
                margin: const EdgeInsets.all(6),
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: pincode.isEmpty ? Colors.transparent : Colors.blue,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Pin Pad
          Table(
            defaultColumnWidth: const FixedColumnWidth(60),
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            children: [
              TableRow(
                children: [
                  _PinButton(label: Text("1"), onTap: () => _addDigit("1")),
                  _PinButton(label: Text("2"), onTap: () => _addDigit("2")),
                  _PinButton(label: Text("3"), onTap: () => _addDigit("3")),
                ],
              ),
              TableRow(
                children: [
                  _PinButton(label: Text("4"), onTap: () => _addDigit("4")),
                  _PinButton(label: Text("5"), onTap: () => _addDigit("5")),
                  _PinButton(label: Text("6"), onTap: () => _addDigit("6")),
                ],
              ),
              TableRow(
                children: [
                  _PinButton(label: Text("7"), onTap: () => _addDigit("7")),
                  _PinButton(label: Text("8"), onTap: () => _addDigit("8")),
                  _PinButton(label: Text("9"), onTap: () => _addDigit("9")),
                ],
              ),
              TableRow(
                children: [
                  _PinButton(label: Icon(LucideIcons.delete), onTap: _removeDigit),
                  _PinButton(label: Text("0"), onTap: () => _addDigit("0")),
                  const SizedBox.shrink(),
                ],
              ),
            ],
          ),
        ]
      ),
      actions: [
        PhotoBoothOutlinedButton(
          title: 'Cancel',
          onPressed: () => context.pop(null),
        ),
        PhotoBoothFilledButton(
          title: "OK",
          onPressed: () => context.pop(pincode),
        ),
      ],
      dialogType: ModalDialogType.input,
    );
  }

    void _addDigit(String digit) {
    if (pincode.length < 6) {
      setState(() => pincode += digit);
    }
  }

  void _removeDigit() {
    if (pincode.isNotEmpty) {
      setState(() => pincode = pincode.substring(0, pincode.length - 1));
    }
  }

}

class _PinButton extends StatelessWidget {
  final Widget label;
  final VoidCallback onTap;

  const _PinButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(8),
      width: 64,
      height: 64,
      child: FilledButton(
        onPressed: onTap,
        style: (FluentTheme.of(context).buttonTheme.filledButtonStyle ?? ButtonStyle()).copyWith(
          shape: WidgetStatePropertyAll(ContinuousRectangleBorder(borderRadius: BorderRadius.circular(32))),
        ),
        child: DefaultTextStyle.merge(
          style: TextStyle(fontSize: 20),
          child: label,
        ),
      ),
    );
  }
}
