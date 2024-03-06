import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

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
          ),
          Flexible(
            child: Center(
              child: Text(
                title,
                style: const TextStyle(color: Colors.white, fontSize: 22),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

}
