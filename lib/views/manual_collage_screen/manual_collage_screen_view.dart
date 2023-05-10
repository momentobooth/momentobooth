import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:momento_booth/views/base/screen_view_base.dart';
import 'package:momento_booth/views/custom_widgets/image_with_loader_fallback.dart';
import 'package:momento_booth/views/custom_widgets/photo_collage.dart';
import 'package:momento_booth/views/manual_collage_screen/manual_collage_screen_controller.dart';
import 'package:momento_booth/views/manual_collage_screen/manual_collage_screen_view_model.dart';

class ManualCollageScreenView extends ScreenViewBase<ManualCollageScreenViewModel, ManualCollageScreenController> {

  const ManualCollageScreenView({
    required super.viewModel,
    required super.controller,
    required super.contextAccessor,
  });
  
  @override
  Widget get body {
    return Row(
      children: [
        Flexible(child: _photoGrid),
        Flexible(
          fit: FlexFit.tight,
          child: _rightColumn
        ),
      ],
    );
  }

  Widget _photoInst(SelectableImage image) {
    return Observer(
      builder: (context) => Stack(
        children: [
          Center(
            child: ImageWithLoaderFallback.file(image.file, fit: BoxFit.contain),
          ),
          AnimatedOpacity(
            opacity: image.isSelected ? 1 : 0,
            duration: Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ColoredBox(color: Color(0x80000000)),
                Center(
                  child: Text("${image.selectedIndex+1}/${viewModel.numSelected}", style: theme.subTitleStyle,),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget get _photoGrid {
    return Observer(
      builder: (context) => GridView.count(
        padding: EdgeInsets.symmetric(horizontal: 30, vertical: 10),
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
            child: GestureDetector(
              onTap: controller.refreshImageList,
              child: AutoSizeText("Refresh", style: theme.titleStyle),
            ),
          ),
        ],
      ),
    );
  }

  Widget get _rightColumn {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        children: [
          Flexible(
            flex: 1,
            child: SizedBox()
          ),
          Expanded(
            flex: 10,
            child: _collage,
          ),
          Flexible(
            flex: 2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                GestureDetector(
                  onTap: controller.clearSelection,
                  child: AutoSizeText("Clear", style: theme.titleStyle,)
                ),
                Observer(
                  builder: (context) => AnimatedOpacity(
                    duration: viewModel.opacityDuraction,
                    opacity: viewModel.isSaving ? 0.5 : 1,
                    child: GestureDetector(
                      onTap: controller.captureCollage,
                      child: AutoSizeText(viewModel.isSaving ? "Saving..." : "Save", style: theme.titleStyle,)
                    ),
                  ),
                ),
              ],
            )
          ),
        ],
      ),
    );
  }

  Widget get _collage {
    return Observer(
      builder: (context) => AnimatedRotation(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        turns: -0.25 * viewModel.rotation, // could also use controller.collageKey.currentState!.rotation
        child: Container(
          decoration: BoxDecoration(
            color: Color.fromARGB(255, 255, 255, 255),
            boxShadow: [theme.chooseCaptureModeButtonShadow],
          ),
          child: FittedBox(
            child: PhotoCollage(
              key: controller.collageKey,
              aspectRatio: 1/viewModel.collageAspectRatio,
              padding: viewModel.collagePadding,
            ),
          ),
        ),
      ),
    );
  }

}
