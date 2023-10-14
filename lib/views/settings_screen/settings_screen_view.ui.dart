part of 'settings_screen_view.dart';

Widget _getUiSettings(SettingsScreenViewModel viewModel, SettingsScreenController controller) {
  return FluentSettingsPage(
    title: "User interface",
    blocks: [
      ComboBoxCard<Language>(
        icon: FluentIcons.locale_language,
        title: "Language",
        subtitle: "The language used in the app (except for this settings screen)",
        items: viewModel.languages,
        value: () => viewModel.languageSetting,
        onChanged: controller.onLanguageChanged,
      ),
      FluentSettingsBlock(
        title: "Animations",
        settings: [
          BooleanInputCard(
            icon: FluentIcons.favorite_star,
            title: "Display confetti 🎉",
            subtitle: "If enabled, confetti will shower the share screen!",
            value: () => viewModel.displayConfettiSetting,
            onChanged: controller.onDisplayConfettiChanged,
          ),
          ComboBoxCard<ScreenTransitionAnimation>(
            icon: FluentIcons.transition_effect,
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
            icon: FluentIcons.volume3,
            title: "Enable sound effects 🔊",
            subtitle: "If enabled, sound effects will be enabled",
            value: () => viewModel.enableSfxSetting,
            onChanged: controller.onEnableSfxChanged,
          ),
          Observer(builder: (_) {
            if (viewModel.enableSfxSetting) {
              return FilePickerCard(
                icon: FluentIcons.clicked,
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
                icon: FluentIcons.volume3,
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
          ComboBoxCard<FilterQuality>(
            icon: FluentIcons.transition_effect,
            title: "Filter quality for screen transitions",
            subtitle: "The filter quality used for the screen transition scale animation",
            items: viewModel.filterQualityOptions,
            value: () => viewModel.screenTransitionAnimationFilterQuality,
            onChanged: controller.onScreenTransitionAnimationFilterQualityChanged,
          ),
          ComboBoxCard<FilterQuality>(
            icon: FluentIcons.front_camera,
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
