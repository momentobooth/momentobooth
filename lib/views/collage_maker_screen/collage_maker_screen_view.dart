import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_layout_grid/flutter_layout_grid.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:momento_booth/managers/photos_manager.dart';
import 'package:momento_booth/managers/settings_manager.dart';
import 'package:momento_booth/views/base/screen_view_base.dart';
import 'package:momento_booth/views/collage_maker_screen/collage_maker_screen_controller.dart';
import 'package:momento_booth/views/collage_maker_screen/collage_maker_screen_view_model.dart';
import 'package:momento_booth/views/custom_widgets/photo_collage.dart';
import 'package:momento_booth/views/custom_widgets/photo_container.dart';

class CollageMakerScreenView extends ScreenViewBase<CollageMakerScreenViewModel, CollageMakerScreenController> {

  const CollageMakerScreenView({
    required super.viewModel,
    required super.controller,
    required super.contextAccessor,
  });
  
  @override
  Widget get body {
    return Stack(
      clipBehavior: Clip.none,
      fit: StackFit.expand,
      children: [
        Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Flexible(
              flex: 2,
              child: _leftColumn
            ),
            Flexible(
              flex: 3,
              child: _rightColumn,
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 10),
          child: Align(
            alignment: Alignment.bottomRight,
            child: Observer(
              builder: (context) => AnimatedOpacity(
                duration: viewModel.opacityDuraction,
                opacity: viewModel.readyToContinue ? 1 : 0.5,
                child: GestureDetector(
                  onTap: controller.onContinueTap,
                  child: AutoSizeText(
                    "${localizations.genericContinueButton} →",
                    style: theme.subTitleStyle,
                    maxLines: 1,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget get _leftColumn {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AutoSizeText(
            localizations.collageMakerScreenPicturesShotTitle,
            style: theme.titleStyle,
            maxLines: 1,
          ),
          _photoSelector,
          Observer(
            builder: (context) => AutoSizeText(
              localizations.collageMakerScreenPhotoCounter(viewModel.numSelected),
              style: theme.titleStyle,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget get _photoSelector {
    return LayoutGrid(
      areas: '''
          picture1 picture2
          picture3 picture4
        ''',
      rowSizes: const [auto, auto],
      columnSizes: [1.fr, 1.fr],
      columnGap: 12,
      rowGap: 12,
      children: [
        for (int i = 0; i < PhotosManager.instance.photos.length; i++)
          GestureDetector(
            onTap: () => controller.togglePicture(i),
            child: Observer(builder: (context) {
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  SizedBox.expand(
                    child: AspectRatio(
                      aspectRatio: SettingsManager.instance.settings.hardware.liveViewAndCaptureAspectRatio,
                      child: PhotoContainer.memory(PhotosManager.instance.photos[i].data),
                    ),
                  ),
                  AnimatedOpacity(
                    opacity: PhotosManager.instance.chosen.contains(i) ? 1 : 0,
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    child: Stack(
                      clipBehavior: Clip.none,
                      fit: StackFit.expand,
                      children: [
                        const ColoredBox(color: Color(0x80000000)),
                        Center(
                          child: Text(
                            (PhotosManager.instance.chosen.indexOf(i) + 1).toString(),
                            style: theme.subTitleStyle,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }),
          ).inGridArea('picture${i + 1}'),
      ],
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
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: AutoSizeText(localizations.collageMakerScreenCollageTitle, style: theme.titleStyle),
            ),
          ),
          Expanded(
            flex: 10,
            child: _collage,
          ),
          const Flexible(
            flex: 1,
            child: SizedBox(),
          ),
        ],
      ),
    );
  }

  Widget get _collage {
    return Observer(
      builder: (context) => AnimatedRotation(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        turns: -0.25 * viewModel.rotation, // could also use controller.collageKey.currentState!.rotation
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 255, 255, 255),
            boxShadow: [theme.chooseCaptureModeButtonShadow],
          ),
          child: PhotoCollage(
            key: controller.collageKey,
            aspectRatio: 1/viewModel.collageAspectRatio,
            padding: viewModel.collagePadding,
          ),
        ),
      ),
    );
  }

}
