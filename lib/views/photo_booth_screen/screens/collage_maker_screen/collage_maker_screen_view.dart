import 'package:auto_size_text/auto_size_text.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_layout_grid/flutter_layout_grid.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:momento_booth/main.dart';
import 'package:momento_booth/managers/photos_manager.dart';
import 'package:momento_booth/managers/settings_manager.dart';
import 'package:momento_booth/views/base/screen_view_base.dart';
import 'package:momento_booth/views/components/animations/rotating_collage_box.dart';
import 'package:momento_booth/views/components/imaging/image_with_loader_fallback.dart';
import 'package:momento_booth/views/components/imaging/photo_collage.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/collage_maker_screen/collage_maker_screen_controller.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/collage_maker_screen/collage_maker_screen_view_model.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/components/buttons/photo_booth_button.dart';

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
              builder: (context) => Stack(
                alignment: Alignment.center,
                children: [
                  if (!viewModel.readyToContinue && viewModel.numSelected > 0) ProgressRing(),
                  PhotoBoothButton.navigation(
                    onPressed: viewModel.readyToContinue ? controller.onContinueTap : null,
                    title: localizations.genericContinueButton,
                  ),
                ],
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
            style: theme.titleTheme.style,
            maxLines: 1,
          ),
          _photoSelector,
          Observer(
            builder: (context) => AutoSizeText(
              localizations.collageMakerScreenPhotoCounter(viewModel.numSelected),
              style: theme.titleTheme.style,
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
        for (int i = 0; i < getIt<PhotosManager>().photos.length; i++)
          GestureDetector(
            onTap: () => controller.togglePicture(i),
            child: Observer(builder: (context) {
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  SizedBox.expand(
                    child: AspectRatio(
                      aspectRatio: getIt<SettingsManager>().settings.hardware.liveViewAndCaptureAspectRatio,
                      child: ImageWithLoaderFallback.memory(getIt<PhotosManager>().photos[i].data, applyRotateFlipCrop: true),
                    ),
                  ),
                  AnimatedOpacity(
                    opacity: getIt<PhotosManager>().chosen.contains(i) ? 1 : 0,
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    child: Stack(
                      clipBehavior: Clip.none,
                      fit: StackFit.expand,
                      children: [
                        const ColoredBox(color: Color(0x80000000)),
                        Center(
                          child: Text(
                            (getIt<PhotosManager>().chosen.indexOf(i) + 1).toString(),
                            style: theme.subtitleTheme.style,
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
              child: AutoSizeText(localizations.collageMakerScreenCollageTitle, style: theme.titleTheme.style),
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
      builder: (context) => RotatingCollageBox(
        turns: -0.25 * viewModel.rotation,
        collage: PhotoCollage(
          key: controller.collageKey,
          aspectRatio: 1 / viewModel.collageAspectRatio,
          padding: viewModel.collagePadding,
        ),
        onRotateCompleted: controller.captureCollage,
      ),
    );
  }

}
