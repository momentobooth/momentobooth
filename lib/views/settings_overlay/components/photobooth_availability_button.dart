import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:momento_booth/extensions/go_router_extension.dart';
import 'package:momento_booth/main.dart';
import 'package:momento_booth/managers/settings_manager.dart';
import 'package:momento_booth/views/not_available_screen/not_available_screen.dart';
import 'package:momento_booth/views/onboarding_screen/onboarding_screen.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/start_screen/start_screen.dart';

class PhotoboothAvailabilityButton extends StatelessWidget {
  const PhotoboothAvailabilityButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (context) {
        bool photoboothIsAvailable = getIt<SettingsManager>().settings.photoboothIsAvailable;

        return Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 4,
          children: [
            Text.rich(TextSpan(
              children: [
                TextSpan(text: 'MomentoBooth is: '),
                TextSpan(
                  text: photoboothIsAvailable ? 'Active' : 'Inactive',
                  style: FluentTheme.of(context).typography.body!.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            )),
            IconButton(
              icon: Icon(LucideIcons.power),
              style: ButtonStyle(
                foregroundColor: WidgetStatePropertyAll(
                  photoboothIsAvailable ? material.Colors.lightGreen : material.Colors.red,
                ),
                iconSize: WidgetStatePropertyAll(24),
              ),
              onPressed: () => _onPressed(context),
            ),
          ],
        );
      },
    );
  }

  void _onPressed(BuildContext context) {
    bool photoboothIsAvailable = getIt<SettingsManager>().settings.photoboothIsAvailable;

    getIt<SettingsManager>().updateAndSave(
      getIt<SettingsManager>().settings.copyWith(photoboothIsAvailable: !photoboothIsAvailable),
    );

    GoRouter router = GoRouter.of(context);
    if (router.currentLocation != OnboardingScreen.defaultRoute) {
      router.go(photoboothIsAvailable ? NotAvailableScreen.defaultRoute : StartScreen.defaultRoute);
    }
  }
}
