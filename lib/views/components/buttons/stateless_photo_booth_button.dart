import 'package:fluent_ui/fluent_ui.dart';

abstract class StatelessPhotoBoothButton extends StatelessWidget {

  final String title;
  final IconData? icon;
  final VoidCallback? onPressed;

  const StatelessPhotoBoothButton({
    super.key,
    required this.title,
    this.icon,
    this.onPressed,
  }) : super();

}
