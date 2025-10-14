import 'dart:math';

import 'package:collection/collection.dart';
import 'package:draggable_scrollbar/draggable_scrollbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:momento_booth/models/gallery_group.dart';
import 'package:momento_booth/models/gallery_image.dart';
import 'package:momento_booth/views/base/screen_view_base.dart';
import 'package:momento_booth/views/components/imaging/image_with_loader_fallback.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/components/buttons/photo_booth_button.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/components/text/auto_size_text_and_icon.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/gallery_screen/components/filter_bar.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/gallery_screen/gallery_screen_controller.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/gallery_screen/gallery_screen_view_model.dart';
import 'package:smooth_scroll_multiplatform/smooth_scroll_multiplatform.dart';

enum SortBy { time, people }

class GalleryScreenView extends ScreenViewBase<GalleryScreenViewModel, GalleryScreenController> {

  const GalleryScreenView({
    required super.viewModel,
    required super.controller,
    required super.contextAccessor,
  });

  static const double groupHeaderHeight = 112;
  static const int imagesPerRow = 4;

  @override
  Widget get body {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
          child: DynMouseScroll(
            builder: (context, scrollController, scrollPhysics) => Observer(
              builder: (context) => DraggableScrollbar.semicircle(
                alwaysVisibleScrollThumb: true,
                controller: scrollController,
                labelConstraints: const BoxConstraints(maxWidth: 200, maxHeight: 50),
                labelTextBuilder: (offset) {
                  final int numGroups = viewModel.imageGroups?.length ?? 0;
                  final List<int> groupImageNums = viewModel.imageGroups?.map((group) => group.images.length).toList() ?? [];
                  final List<String> groupTitles = viewModel.imageGroups?.map((group) => group.title).toList() ?? [];
                  final groupRows = groupImageNums.map((e) => (e / 4).ceil());
                  final double screenHeight = scrollController.position.viewportDimension;

                  const double groupHeaderHeightCompensated = groupHeaderHeight + 50.0;
                  // We need to compensate for the screen height twice because of the way that the comparison is implemented.
                  final double pageLength = scrollController.position.maxScrollExtent + 2 * screenHeight;
                  final double rowHeight = (pageLength - (numGroups * groupHeaderHeightCompensated)) / groupRows.sum;
                  final sectionLengths = groupRows.map((element) => element*rowHeight + groupHeaderHeightCompensated).toList();

                  int currentIndex = 0;
                  double currentLength = 0;
                  for (; offset > currentLength; currentIndex++) {
                    currentLength += sectionLengths[currentIndex];
                  }
                  currentIndex = max(currentIndex - 1, 0);

                  return Text(groupTitles[currentIndex], style: const TextStyle(fontSize: 22));
                },
                child: CustomScrollView(
                  controller: scrollController,
                  physics: scrollPhysics,
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
                            child: AutoSizeTextAndIcon(
                              text: group.title,
                              style: theme.subtitleTheme.style,
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
                                MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: GestureDetector(
                                    onTap: () => controller.openPhoto(image.file),
                                    child: Hero(
                                      tag: image.file.path,
                                      child: ImageWithLoaderFallback.file(
                                        image.file,
                                        fit: BoxFit.contain,
                                        cacheWidth: View.of(context).physicalSize.width ~/ imagesPerRow,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ]),
                  ],
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 80),
          child: Row(
            children: [
              const Expanded(child: SizedBox()),
              Container(
                height: 60,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(10)),
                  color: Color.fromARGB(130, 48, 48, 48),
                ),
                child: FilterBar(viewModel: viewModel, controller: controller),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(30),
          child: Align(
            alignment: Alignment.bottomLeft,
            child: PhotoBoothButton.navigation(
              onPressed: controller.onPressedBack,
              child: AutoSizeTextAndIcon(
                text: localizations.genericBackButton,
                leftIcon: LucideIcons.stepBack,
              ),
            ),
          ),
        ),
      ],
    );
  }

}
