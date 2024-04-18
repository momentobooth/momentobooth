import 'dart:math';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:momento_booth/models/gallery_group.dart';
import 'package:momento_booth/models/gallery_image.dart';
import 'package:momento_booth/views/base/screen_view_base.dart';
import 'package:momento_booth/views/custom_widgets/draggable_scrollbar_override.dart';
import 'package:momento_booth/views/custom_widgets/image_with_loader_fallback.dart';
import 'package:momento_booth/views/custom_widgets/wrappers/animated_box_decoration_hero.dart';
import 'package:momento_booth/views/gallery_screen/gallery_screen_controller.dart';
import 'package:momento_booth/views/gallery_screen/gallery_screen_view_model.dart';
import 'package:smooth_scroll_multiplatform/smooth_scroll_multiplatform.dart';

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
          child: DynMouseScroll(
            builder: (context, scrollController, scrollPhysics) => Observer(
              builder: (context) => MomentoDraggableScrollbar.semicircle(
                alwaysVisibleScrollThumb: true,
                controller: scrollController,
                labelConstraints: const BoxConstraints(maxWidth: 200, maxHeight: 50),
                labelTextBuilder: (offset) {
                  final int numGroups = viewModel.imageGroups?.length ?? 0;
                  final List<int> groupImageNums = viewModel.imageGroups?.map((group) => group.images.length).toList() ?? [];
                  final List<String> groupTitles = viewModel.imageGroups?.map((group) => group.title).toList() ?? [];
                  final groupRows = groupImageNums.map((e) => (e / 4).ceil());
                  final double screenHeight = scrollController.position.viewportDimension;
              
                  final double groupHeaderHeightCompensated = groupHeaderHeight + 50.0;
                  // We need to compensate for the screenheight twice because of the way that the comparison is implemented.
                  final double pageLength = scrollController.position.maxScrollExtent + 2*screenHeight;
                  final double rowHeight = (pageLength - (numGroups * groupHeaderHeightCompensated)) / groupRows.sum;
                  final sectionLengths = groupRows.map((element) => element*rowHeight + groupHeaderHeightCompensated).toList();
              
                  int currentIndex = 0;
                  double currentLength = 0;
                  for (; offset > currentLength; currentIndex++) { currentLength += sectionLengths[currentIndex]; }
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
                            child: Text(
                              group.title,
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
                child: Observer(
                  builder: (context) {
                    return getFilterBar();
                  }
                ),
              ),
            ],
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

  Widget getFilterBar() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text(
          "Order by",
          style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
              fontSize: 18,
              height: 1),
        ),
        const SizedBox(width: 12,),
        FilterChoice(sortBy: viewModel.sortBy, onChanged: viewModel.onSortByChanged),
        const SizedBox(width: 20,),
        if (viewModel.imageNames == null && viewModel.isFaceRecognitionEnabled)
          OutlinedButton.icon(
            onPressed: controller.onFindMyFace,
            style: ButtonStyle(
              backgroundColor: MaterialStateProperty.all(Colors.blue.shade700),
              foregroundColor: MaterialStateProperty.all(Colors.white),
              overlayColor: MaterialStateProperty.all(Colors.blue.shade400),
            ),
            icon: const Icon(Icons.face),
            label: const Text("Find my face"),
          )
        else if (viewModel.imageNames != null)
          OutlinedButton.icon(
            onPressed: controller.clearImageFilter,
            style: ButtonStyle(
              foregroundColor: MaterialStateProperty.all(Colors.white),
              overlayColor: MaterialStateProperty.all(Colors.red.shade900),
              side: MaterialStateProperty.all(const BorderSide(color: Color.fromARGB(255, 255, 117, 117))),
            ),
            icon: const Icon(Icons.filter_alt_off),
            label: const Text("Clear filter"),
          ),
      ],
    );
  }
}

enum SortBy { time, people }

class FilterChoice extends StatelessWidget {
  const FilterChoice({super.key, required this.sortBy, required this.onChanged});
  final SortBy sortBy;
  final ValueChanged<SortBy> onChanged;

  @override
  Widget build(BuildContext context) {
    ButtonStyle style = ButtonStyle(foregroundColor: MaterialStateProperty.all(Colors.white));
    return SegmentedButton<SortBy>(
      style: style,
      segments: const <ButtonSegment<SortBy>>[
        ButtonSegment<SortBy>(
            value: SortBy.time,
            label: Text('Time'),
            icon: Icon(Icons.schedule_rounded)),
        ButtonSegment<SortBy>(
            value: SortBy.people,
            label: Text('Group size'),
            icon: Icon(Icons.groups)),
      ],
      selected: <SortBy>{sortBy},
      onSelectionChanged: (newSelection) {
        // By default there is only a single segment that can be
        // selected at one time, so its value is always the first
        // item in the selected set.
        onChanged(newSelection.first);
      },
    );
  }
}
