part of '../settings_overlay_view.dart';

Widget _getQuickSettings(SettingsOverlayViewModel viewModel, SettingsOverlayController controller) {
  final List<String> elements = [
    "Zero",
    "One",
    "Two",
    "Three",
    "Four",
    "Five",
    "Six",
    "Seven",
    "Eight",
    "A Million Billion Trillion",
    "A much, much longer text that will still fit",
  ];
  return SettingsPage(
    title: 'Quick Settings',
    bodyBuilder: (context, scrollController, scrollPhysics) {
      return Observer(
        builder: (_) => GridView(
          controller: scrollController,
          physics: scrollPhysics,
          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 256,
            crossAxisSpacing: 20.0,
            mainAxisSpacing: 20.0,
          ),
          children: [
            ToggleButton(
              checked: getIt<WindowManager>().isFullScreen,
              onChanged: (_) => getIt<WindowManager>().toggleFullscreen(),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: 32,
                children: [
                  Icon(LucideIcons.fullscreen, size: 64),
                  Text('Full screen'),
                ],
              ),
            )
          ],
        ),
      );
    },
  );
}
