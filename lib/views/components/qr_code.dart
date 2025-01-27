import 'package:flutter/widgets.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';

class QrCode extends StatelessWidget {

  final String data;
  final double size;

  const QrCode({
    super.key,
    required this.data,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: PrettyQrView.data(
        data: data,
        errorCorrectLevel: QrErrorCorrectLevel.L,
        decoration: const PrettyQrDecoration(
          shape: PrettyQrSmoothSymbol(
            roundFactor: 1,
          ),
        ),
      ),
    );
  }

}
