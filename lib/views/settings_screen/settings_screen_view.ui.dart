part of 'settings_screen_view.dart';

Widget _getUiSettings(SettingsScreenViewModel viewModel, SettingsScreenController controller) {
  return FluentSettingsPage(
    title: "Output",
    blocks: [
      FluentSettingsBlock(
        title: "Animations",
        settings: [
          _getBooleanInput(
            icon: FluentIcons.favorite_star,
            title: "Display confetti 🎉",
            subtitle: "If enabled, confetti will shower the share screen!",
            value: () => viewModel.displayConfettiSetting,
            onChanged: controller.onDisplayConfettiChanged,
          ),
          _getComboBoxCard<ScreenTransitionAnimation>(
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
        title: "Advanced",
        settings: [
          _getComboBoxCard<FilterQuality>(
            icon: FluentIcons.transition_effect,
            title: "Filter quality for screen transitions",
            subtitle: "The filter quality used for the screen transition scale animation",
            items: viewModel.filterQualityOptions,
            value: () => viewModel.screenTransitionAnimationFilterQuality,
            onChanged: controller.onScreenTransitionAnimationFilterQualityChanged,
          ),
          _getComboBoxCard<FilterQuality>(
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
