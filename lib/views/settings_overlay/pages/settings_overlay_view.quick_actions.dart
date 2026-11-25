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
            maxCrossAxisExtent: 192,
            crossAxisSpacing: 20.0,
            mainAxisSpacing: 20.0,
          ),
          children: [
            QuickToggle(
              title: 'Full screen',
              icon: LucideIcons.fullscreen,
              checked: getIt<WindowManager>().isFullScreen,
              onChanged: (_) => getIt<WindowManager>().toggleFullscreenSafe(),
            ),
            QuickToggle(
              title: 'Printing',
              icon: LucideIcons.printer,
              checked: viewModel.enablePrintingSetting,
              onChanged: (_) => controller.onEnablePrintingChanged(!viewModel.enablePrintingSetting),
            ),
            if (getIt<PrintingManager>().waitingCopies > 0)
              QuickAction(
                title: [
                  'Print collected sheets (${getIt<PrintingManager>().waitingCopies} copies',
                  if (getIt<PrintingManager>().sheetFills.isNotEmpty) ', ${getIt<PrintingManager>().sheetFills}',
                  ')',
                ].join(),
                icon: LucideIcons.layers,
                onPressed: () => getIt<PrintingManager>().printCollectedSheets(),
              ),
            if (getIt<PrintingManager>().waitingCopies > 0)
              QuickAction(
                title: 'Discard to-be-printed collected copies',
                icon: LucideIcons.trash2,
                iconColor: Colors.orange,
                onPressed: () => _discardCollectedCopies(context),
              ),
            QuickAction(
              title: 'Restart live view',
              icon: LucideIcons.refreshCcw,
              onPressed: () => getIt<LiveViewManager>().restoreLiveView(),
            ),
            QuickAction(
              title: 'Close Settings',
              icon: LucideIcons.x,
              onPressed: () => context.pop(),
            ),
            if (!kIsWeb && Platform.isWindows)
              QuickAction(
                title: 'Restart app',
                icon: LucideIcons.refreshCcw,
                iconColor: Colors.orange,
                onPressed: () async {
                  String? dataDir = getIt<ArgResults>().option('data-dir');
                  await Process.start(
                    Platform.resolvedExecutable,
                    ['--wait-for-pid', '$pid', if (dataDir != null) '--data-dir=$dataDir'],
                    mode: ProcessStartMode.detached,
                  );
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

/// Asks which waiting copies to throw away, if any, and does so.
Future<void> _discardCollectedCopies(BuildContext context) async {
  final printingManager = getIt<PrintingManager>();
  final waiting = printingManager.waitingCopies;
  final stranded = printingManager.strandedCopies;
  // Null when cancelled.
  final strandedOnly = await showDialog<bool>(
    context: context,
    builder: (context) => ContentDialog(
      title: const Text('Discard collected copies'),
      content: Text([
        '$waiting copies wait on stacks.',
        if (stranded > 0 && stranded < waiting) '$stranded of them wait on a stack that does not reach a printer.',
        'Discarded copies are not printed, but their photos stay in the gallery and can be printed again from there.',
      ].join(' ')),
      actions: [
        Button(child: const Text('Cancel'), onPressed: () => Navigator.of(context).pop()),
        if (stranded > 0 && stranded < waiting)
          Button(child: Text('Discard stranded ($stranded)'), onPressed: () => Navigator.of(context).pop(true)),
        FilledButton(child: Text('Discard all ($waiting)'), onPressed: () => Navigator.of(context).pop(false)),
      ],
    ),
  );
  if (strandedOnly == null) return;
  await printingManager.discardCollectedCopies(strandedOnly: strandedOnly);
}
