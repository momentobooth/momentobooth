import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:momento_booth/extensions/build_context_extension.dart';
import 'package:momento_booth/views/base/screen_view_base.dart';
import 'package:momento_booth/views/components/imaging/image_with_loader_fallback.dart';
import 'package:momento_booth/views/components/imaging/photo_collage.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/components/buttons/photo_booth_button.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/components/text/auto_size_text_and_icon.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/manual_collage_screen/manual_collage_screen_controller.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/manual_collage_screen/manual_collage_screen_view_model.dart';

class ManualCollageScreenView extends ScreenViewBase<ManualCollageScreenViewModel, ManualCollageScreenController> {

  const ManualCollageScreenView({
    required super.viewModel,
    required super.controller,
    required super.contextAccessor,
  });

  @override
  Widget get body {
    return KeyboardListener(
      focusNode: viewModel.focusNode,
      onKeyEvent: (_) {
        viewModel
          ..isShiftPressed = HardwareKeyboard.instance.isShiftPressed
          ..isControlPressed = HardwareKeyboard.instance.isControlPressed;
      },
      child: Row(
        children: [
          Flexible(child: _photoGrid),
          Flexible(fit: FlexFit.tight, child: _rightColumn),
        ],
      ),
    );
  }

  Widget _photoInst(SelectableImage image) {
    return Observer(
      builder: (context) => Stack(
        clipBehavior: Clip.none,
        children: [
          Center(
            child: ImageWithLoaderFallback.file(image.file, fit: BoxFit.contain, cacheWidth: 256),
          ),
          AnimatedOpacity(
            opacity: image.isSelected ? 1 : 0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            child: Stack(
              clipBehavior: Clip.none,
              fit: StackFit.expand,
              children: [
                const ColoredBox(color: Color(0x80000000)),
                Center(
                  child: Text("${image.selectedIndex+1}/${viewModel.numSelected}", style: theme.subtitleTheme.style),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget get _photoGrid {
    return Observer(
      builder: (context) => GridView.count(
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
        mainAxisSpacing: 20,
        crossAxisSpacing: 20,
        crossAxisCount: 4,
        childAspectRatio: 1.5,
        children: [
          for (var image in viewModel.fileList)
            GestureDetector(
              onTap: () => controller.tapPhoto(image),
              child: _photoInst(image),
            ),
          Center(
            child: PhotoBoothButton.action(
              onPressed: controller.refreshImageList,
              child: AutoSizeTextAndIcon(text: localizations.genericRefreshButton),
            ),
          ),
        ],
      ),
    );
  }

  static final checkboxStyle = CheckboxThemeData(
    foregroundColor: WidgetStateProperty.all(Colors.white),
    uncheckedDecoration: WidgetStateProperty.all(
      BoxDecoration(border: Border.all(color: Colors.white), borderRadius: BorderRadius.circular(6)),
    ),
  );

  Widget get _rightColumn {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        children: [
          Expanded(flex: 10, child: _collage),
          const SizedBox(height: 30),
          Flexible(
            child: Row(
              children: [
                Observer(
                  builder: (context) => Transform.scale(
                    scale: 1.5,
                    alignment: Alignment.centerLeft,
                    child: Checkbox(
                      style: checkboxStyle,
                      content: const Text("Print on save"),
                      checked: viewModel.printOnSave,
                      onChanged: (b) => viewModel.printOnSave = b!,
                    ),
                  ),
                ),
                const SizedBox(width: 85),
                Observer(
                  builder: (context) => Transform.scale(
                    scale: 1.5,
                    alignment: Alignment.centerLeft,
                    child: Checkbox(
                      style: checkboxStyle,
                      content: const Text("Clear on save"),
                      checked: viewModel.clearOnSave,
                      onChanged: (b) => viewModel.clearOnSave = b!,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Flexible(
            flex: 2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                PhotoBoothButton.action(
                  onPressed: controller.clearSelection,
                  child: AutoSizeTextAndIcon(text: localizations.genericClearButton),
                ),
                Observer(
                  builder: (context) => AnimatedOpacity(
                    duration: viewModel.opacityDuraction,
                    opacity: viewModel.isSaving ? 0.5 : 1,
                    child: PhotoBoothButton.action(
                      onPressed: controller.captureCollage,
                      child: AutoSizeTextAndIcon(
                        text: viewModel.isSaving ? localizations.manualCollageScreenSaving : localizations.genericSaveButton,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget get _collage {
    Widget collage = PhotoCollage(
      key: controller.collageKey,
      aspectRatio: 1 / viewModel.collageAspectRatio,
      padding: viewModel.collagePadding,
    );

    return Observer(
      builder: (context) => AnimatedRotation(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        turns: -0.25 * viewModel.rotation, // could also use controller.collageKey.currentState!.rotation
        child: context.theme.collagePreviewTheme.frameBuilder?.call(context, collage) ?? collage,
      ),
    );
  }

}
