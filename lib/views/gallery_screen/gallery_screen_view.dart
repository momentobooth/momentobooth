import 'dart:math';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:momento_booth/models/gallery_group.dart';
import 'package:momento_booth/models/gallery_image.dart';
import 'package:momento_booth/views/base/screen_view_base.dart';
import 'package:momento_booth/views/custom_widgets/image_with_loader_fallback.dart';
import 'package:momento_booth/views/custom_widgets/wrappers/animated_box_decoration_hero.dart';
import 'package:momento_booth/views/gallery_screen/draggable_scrollbar_override.dart';
import 'package:momento_booth/views/gallery_screen/gallery_screen_controller.dart';
import 'package:momento_booth/views/gallery_screen/gallery_screen_view_model.dart';

class GalleryScreenView extends ScreenViewBase<GalleryScreenViewModel, GalleryScreenController> {

  const GalleryScreenView({
    required super.viewModel,
    required super.controller,
    required super.contextAccessor,
  });
  
  static double groupHeaderHeight = 100;
  static int imagesPerRow = 4;
  
  @override
  Widget get body {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
          child: Observer(
            builder: (context) => MomentoDraggableScrollbar.semicircle(
              alwaysVisibleScrollThumb: true,
              controller: viewModel.myScrollController,
              labelConstraints: const BoxConstraints(maxWidth: 200, maxHeight: 50),
              labelTextBuilder: (offset) {
                final int numGroups = viewModel.imageGroups?.length ?? 0;
                final List<int> groupImageNums = viewModel.imageGroups?.map((group) => group.images.length).toList() ?? [];
                final List<DateTime> timeslots = viewModel.imageGroups?.map((group) => group.createdDayAndHour ?? DateTime(1970)).toList() ?? [];
                final groupRows = groupImageNums.map((e) => (e / 4).ceil());
                final double screenHeight = viewModel.myScrollController.position.viewportDimension;

                final double groupHeaderHeightCompensated = groupHeaderHeight + 50.0;
                // We need to compensate for the screenheight twice because of the way that the comparison is implemented.
                final double pageLength = viewModel.myScrollController.position.maxScrollExtent + 2*screenHeight;
                final double rowHeight = (pageLength - (numGroups * groupHeaderHeightCompensated)) / groupRows.sum;
                final sectionLengths = groupRows.map((element) => element*rowHeight + groupHeaderHeightCompensated).toList();

                int currentIndex = 0;
                double currentLength = 0;
                for (; offset > currentLength; currentIndex++) { currentLength += sectionLengths[currentIndex]; }
                currentIndex = max(currentIndex-1, 0);
          
                return Text(viewModel.formatter.format(timeslots[currentIndex]), style: const TextStyle(fontSize: 22),);
              },
              child: CustomScrollView(
                controller: viewModel.myScrollController,
                slivers: [
                  for (GalleryGroup group in viewModel.imageGroups ?? [])
                    SliverMainAxisGroup(slivers: [
                      SliverAppBar(
                        pinned: true,
                        toolbarHeight: groupHeaderHeight,
                        forceMaterialTransparency: true,
                        automaticallyImplyLeading: false,
                        title: Padding(
                          padding: const EdgeInsets.fromLTRB(10, 0, 0, 0),
                          child: Text(
                            viewModel.formatter.format(group.createdDayAndHour ?? DateTime(1970)),
                            style: theme.subTitleStyle,
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                        sliver: SliverGrid.count(
                          mainAxisSpacing: 20,
                          crossAxisSpacing: 20,
                          crossAxisCount: imagesPerRow,
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
                        ),
                      )
                    ]),
                ],
              ),
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
