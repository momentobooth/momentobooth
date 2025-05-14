part of '../settings_overlay_view.dart';

Widget _getUiSettings(SettingsOverlayViewModel viewModel, SettingsOverlayController controller) {
  return SettingsPage(
    title: "User interface",
    blocks: [
      SettingsNumberEditTile(
        icon: LucideIcons.timer,
        title: "Return to home timeout",
        subtitle: "The time in seconds before the app returns to the home screen. Set to 0 to disable.",
        value: () => viewModel.returnToHomeTimeoutSeconds,
        onFinishedEditing: controller.onReturnToHomeTimeoutSecondsChanged,
      ),
      SettingsComboBoxTile<Language>(
        icon: LucideIcons.languages,
        title: "Language",
        subtitle: "The language used in the app (except for this settings screen).",
        items: viewModel.languages,
        value: () => viewModel.languageSetting,
        onChanged: controller.onLanguageChanged,
      ),
      SettingsToggleTile(
        icon: LucideIcons.mouse,
        title: "Allow scroll gesture with mouse",
        subtitle: "If enabled, the touch scrolling gesture can be simulated using click and drag with a standard mouse. This might workaround Flutter touch gesture support on Linux also.",
        value: () => viewModel.allowScrollGestureWithMouse,
        onChanged: controller.onAllowScrollGestureWithMouseChanged,
      ),
      SettingsSection(
        title: "Animations",
        settings: [
          // FIXME: Add functionality
          // BooleanInputCard(
          //   icon: LucideIcons.partyPopper,
          //   title: "Disable confetti 🚫🎉",
          //   subtitle: "If enabled, confetti will be disabled on the share screen, even if enabled by the project.",
          //   value: () => viewModel.disableConfettiSetting,
          //   onChanged: controller.onDisableConfettiChanged,
          // ),
          SettingsComboBoxTile<ScreenTransitionAnimation>(
            icon: LucideIcons.arrowRightLeft,
            title: "Screen transition animation",
            subtitle: "The animation used when switching between screens",
            items: viewModel.screenTransitionAnimations,
            value: () => viewModel.screenTransitionAnimation,
            onChanged: controller.onScreenTransitionAnimationChanged,
          ),
        ],
      ),
      SettingsSection(
        title: "Sound effects",
        settings: [
          SettingsToggleTile(
            icon: LucideIcons.volume2,
            title: "Enable sound effects",
            subtitle: "If enabled, sound effects will be enabled",
            value: () => viewModel.enableSfxSetting,
            onChanged: controller.onEnableSfxChanged,
          ),
          Observer(builder: (_) {
            if (viewModel.enableSfxSetting) {
              return SettingsFileSelectTile(
                icon: LucideIcons.mousePointerClick,
                title: "Click sound effect",
                subtitle: "The sound effect that will be played when the screen is tapped or something is clicked",
                controller: controller.clickSfxFileController,
                onChanged: controller.onClickSfxFileChanged,
              );
            }
            return const SizedBox();
          }),
          Observer(builder: (_) {
            if (viewModel.enableSfxSetting) {
              return SettingsFileSelectTile(
                icon: LucideIcons.share,
                title: "Share screen sound effect",
                subtitle: "The sound effect that will be played when the share screen is opened",
                controller: controller.shareScreenSfxFileController,
                onChanged: controller.onShareScreenSfxFileChanged,
              );
            }
            return const SizedBox();
          }),
        ],
      ),
      SettingsSection(
        title: "Advanced",
        settings: [
          SettingsComboBoxTile<BackgroundBlur>(
            icon: LucideIcons.brickWall,
            title: "Background blur",
            subtitle: "Sets the background blur implementation. Currently there are no options for this setting except disabling it for testing.",
            items: viewModel.backgroundBlurOptions,
            value: () => viewModel.backgroundBlur,
            onChanged: controller.onBackgroundBlurChanged,
          ),
          SettingsComboBoxTile<FilterQuality>(
            icon: LucideIcons.arrowRightLeft,
            title: "Filter quality for screen transitions",
            subtitle: "The filter quality used for the screen transition scale animation",
            items: viewModel.filterQualityOptions,
            value: () => viewModel.screenTransitionAnimationFilterQuality,
            onChanged: controller.onScreenTransitionAnimationFilterQualityChanged,
          ),
          SettingsComboBoxTile<FilterQuality>(
            icon: LucideIcons.cctv,
            title: "Filter quality for live view",
            subtitle: "The filter quality used for the live view",
            items: viewModel.filterQualityOptions,
            value: () => viewModel.liveViewFilterQuality,
            onChanged: controller.onLiveViewFilterQualityChanged,
          ),
        ],
      ),
    ],
  );
}
