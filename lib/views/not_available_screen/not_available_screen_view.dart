import 'package:fluent_ui/fluent_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:momento_booth/main.dart';
import 'package:momento_booth/managers/settings_manager.dart';
import 'package:momento_booth/views/base/screen_view_base.dart';
import 'package:momento_booth/views/components/backgrounds/animated_circles_background.dart';
import 'package:momento_booth/views/components/imaging/shader_viewer.dart';
import 'package:momento_booth/views/not_available_screen/not_available_screen_controller.dart';
import 'package:momento_booth/views/not_available_screen/not_available_screen_view_model.dart';
import 'package:momento_booth/views/onboarding_screen/components/onboarding_wizard.dart';

class NotAvailableScreenView extends ScreenViewBase<NotAvailableScreenViewModel, NotAvailableScreenController> {

  const NotAvailableScreenView({
    required super.viewModel,
    required super.controller,
    required super.contextAccessor,
  });

  @override
  Widget get body {
    bool enableScreensavers = getIt<SettingsManager>().settings.ui.enableScreensaversWhenUnavailable;
    return Stack(
      fit: StackFit.expand,
      children: [
        if (enableScreensavers)
          ShaderViewer(assetKey: 'assets/shaders/starfield-dots.frag', timeDilation: 5),
        if (!enableScreensavers)
          const ColoredBox(color: Colors.white),
        if (!enableScreensavers)
          const AnimatedCirclesBackground(),
        Center(
          child: OnboardingWizard(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 64,
              children: [
                Icon(LucideIcons.power, size: 128),
                Text(
                  'MomentoBooth is currently not available',
                  style: FluentTheme.of(context).typography.titleLarge,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

}
