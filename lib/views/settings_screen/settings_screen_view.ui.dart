part of 'settings_screen_view.dart';

Widget _getUiSettings(SettingsScreenViewModel viewModel, SettingsScreenController controller) {
  return FluentSettingsPage(
    title: "User interface",
    blocks: [
      ColorInputCard(
        icon: LucideIcons.paintbrushVertical,
        title: "Primary color",
        subtitle: "The primary color of the app",
        value: () => viewModel.primaryColorSetting,
        onChanged: controller.onPrimaryColorChanged,
      ),
      NumberInputCard(
        icon: LucideIcons.timer,
        title: "Return to home timeout",
        subtitle: "The time in seconds before the app returns to the home screen. Set to 0 to disable.",
        value: () => viewModel.returnToHomeTimeoutSeconds,
        onFinishedEditing: controller.onReturnToHomeTimeoutSecondsChanged,
      ),
      ComboBoxCard<Language>(
        icon: LucideIcons.languages,
        title: "Language",
        subtitle: "The language used in the app (except for this settings screen).",
        items: viewModel.languages,
        value: () => viewModel.languageSetting,
        onChanged: controller.onLanguageChanged,
      ),
      BooleanInputCard(
        icon: LucideIcons.mouse,
        title: "Allow scroll gesture with mouse",
        subtitle: "If enabled, the touch scrolling gesture can be simulated using click and drag with a standard mouse. This might workaround Flutter touch gesture support on Linux also.",
        value: () => viewModel.allowScrollGestureWithMouse,
        onChanged: controller.onAllowScrollGestureWithMouseChanged,
      ),
      FluentSettingsBlock(
        title: "Animations",
        settings: [
          BooleanInputCard(
            icon: LucideIcons.partyPopper,
            title: "Display confetti 🎉",
            subtitle: "If enabled, confetti will shower the share screen!",
            value: () => viewModel.displayConfettiSetting,
            onChanged: controller.onDisplayConfettiChanged,
          ),
          BooleanInputCard(
            icon: LucideIcons.palette,
            title: "Colorize confetti to the theme color",
            subtitle: "If enabled, confetti will will be various shades of the theme color. Else, random colors will be used.",
            value: () => viewModel.customColorConfettiSetting,
            onChanged: controller.onCustomColorConfettiChanged,
          ),
          ComboBoxCard<ScreenTransitionAnimation>(
            icon: LucideIcons.arrowRightLeft,
            title: "Screen transition animation",
            subtitle: "The animation used when switching between screens",
            items: viewModel.screenTransitionAnimations,
            value: () => viewModel.screenTransitionAnimation,
            onChanged: controller.onScreenTransitionAnimationChanged,
          ),
        ],
      ),
      FluentSettingsBlock(
        title: "Sound effects",
        settings: [
          BooleanInputCard(
            icon: LucideIcons.volume2,
            title: "Enable sound effects 🔊",
            subtitle: "If enabled, sound effects will be enabled",
            value: () => viewModel.enableSfxSetting,
            onChanged: controller.onEnableSfxChanged,
          ),
          Observer(builder: (_) {
            if (viewModel.enableSfxSetting) {
              return FilePickerCard(
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
              return FilePickerCard(
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
      FluentSettingsBlock(
        title: "Advanced",
        settings: [
          ComboBoxCard<BackgroundBlur>(
            icon: LucideIcons.brickWall,
            title: "Background blur",
            subtitle: "Sets the background blur implementation. Currently there are no options for this setting except disabling it for testing.",
            items: viewModel.backgroundBlurOptions,
            value: () => viewModel.backgroundBlur,
            onChanged: controller.onBackgroundBlurChanged,
          ),
          ComboBoxCard<FilterQuality>(
            icon: LucideIcons.arrowRightLeft,
            title: "Filter quality for screen transitions",
            subtitle: "The filter quality used for the screen transition scale animation",
            items: viewModel.filterQualityOptions,
            value: () => viewModel.screenTransitionAnimationFilterQuality,
            onChanged: controller.onScreenTransitionAnimationFilterQualityChanged,
          ),
          ComboBoxCard<FilterQuality>(
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
