part of '../settings_overlay_view.dart';

Widget _getQuickActions(SettingsOverlayViewModel viewModel, SettingsOverlayController controller) {
  return SettingsPage(
    title: 'Quick Actions',
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
            QuickToggle(
              title: 'Full screen',
              icon: LucideIcons.fullscreen,
              checked: getIt<WindowManager>().isFullScreen,
              onChanged: (_) => getIt<WindowManager>().toggleFullscreen(),
            ),
            if (!kIsWeb && Platform.isWindows)
              QuickAction(
                title: 'Restart app',
                icon: LucideIcons.refreshCcw,
                iconColor: Colors.orange,
                onPressed: () async {
                  await Process.start(Platform.resolvedExecutable, ['--wait-for-pid', '$pid'], mode: ProcessStartMode.detached);
                  exit(0);
                },
              ),
            QuickAction(
              title: 'Quit',
              icon: LucideIcons.power,
              iconColor: Colors.red,
              //onPressed: SystemNavigator.pop, // Not working on Windows as of Flutter 3.35.4
              onPressed: () => exit(0),
            ),
          ],
        ),
      );
    },
  );
}
