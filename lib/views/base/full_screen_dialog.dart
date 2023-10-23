import 'package:flutter/widgets.dart';

class FullScreenPopup extends StatelessWidget {

  final Widget child;

  const FullScreenPopup({super.key, required this.child});
  
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            blurRadius: 16,
            spreadRadius: 0,
          ),
        ],
      ),
      margin: const EdgeInsets.all(32),
      clipBehavior: Clip.hardEdge,
      child: child,
    );
  }

}
