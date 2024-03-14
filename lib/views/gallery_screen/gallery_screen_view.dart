import 'package:auto_size_text/auto_size_text.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:draggable_scrollbar/draggable_scrollbar.dart';
import 'package:momento_booth/models/gallery_group.dart';
import 'package:momento_booth/models/gallery_image.dart';
import 'package:momento_booth/views/base/screen_view_base.dart';
import 'package:momento_booth/views/custom_widgets/image_with_loader_fallback.dart';
import 'package:momento_booth/views/custom_widgets/wrappers/animated_box_decoration_hero.dart';
import 'package:momento_booth/views/gallery_screen/gallery_screen_controller.dart';
import 'package:momento_booth/views/gallery_screen/gallery_screen_view_model.dart';

class GalleryScreenView extends ScreenViewBase<GalleryScreenViewModel, GalleryScreenController> {

  const GalleryScreenView({
    required super.viewModel,
    required super.controller,
    required super.contextAccessor,
  });
  
  @override
  Widget get body {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Observer(
          builder: (context) => DraggableScrollbar.semicircle(
            controller: viewModel.myScrollController,
            labelTextBuilder: (offset) {
              final int currentItem = viewModel.myScrollController.hasClients
                  ? (viewModel.myScrollController.offset / viewModel.myScrollController.position.maxScrollExtent * 100).floor()
                  : 0;

              return Text("$currentItem");
            },
            child: CustomScrollView(
              controller: viewModel.myScrollController,
              slivers: [
                for (GalleryGroup group in viewModel.imageGroups ?? [])
                  SliverMainAxisGroup(slivers: [
                    SliverAppBar(
                      pinned: true,
                      title: Text("${group.createdDayAndHour}"),
                    ),
                    SliverGrid.count(
                      mainAxisSpacing: 20,
                      crossAxisSpacing: 20,
                      crossAxisCount: 4,
                      children: [
                        for (GalleryImage image in group.images)
                          GestureDetector(
                            onTap: () => controller.openPhoto(image.file),
                            child: AnimatedBoxDecorationHero(
                              tag: image.file.path,
                              child: ImageWithLoaderFallback.file(image.file, fit: BoxFit.contain),
                            ),
                          ),
                      ],
                    )
                  ]),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(30),
          child: Align(
            alignment: Alignment.bottomLeft,
            child: GestureDetector(
              onTap: controller.onPressedBack,
              child: AutoSizeText(
                "← ${localizations.galleryScreenGoToStartButton}",
                style: theme.subTitleStyle,
              ),
            ),
          ),
        ),
      ],
    );
  }

}
