import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

class LoadingDialog extends StatelessWidget {

  final String title;

  const LoadingDialog({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      height: 200,
      width: 400,
      decoration: ShapeDecoration(
        color: Colors.lightBlueAccent.withOpacity(0.75),
        shape: SmoothRectangleBorder(
          borderRadius: SmoothBorderRadius(
            cornerRadius: 40,
            cornerSmoothing: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Lottie.asset(
            'assets/animations/Animation - 1708738963082.json',
            fit: BoxFit.contain,
            alignment: Alignment.centerLeft,
            frameRate: FrameRate.max,
          ),
          Flexible(
            child: Text(
              title,
              style: const TextStyle(color: Colors.white, fontSize: 22),
            ),
          ),
        ],
      ),
    );
  }

}

@widgetbook.UseCase(
  name: 'Loading Dialog',
  type: LoadingDialog,
)
Widget loadingDialog(BuildContext context) {
  return LoadingDialog(
    title: context.knobs.string(label: 'Title', initialValue: 'Please wait...'),
  );
}
