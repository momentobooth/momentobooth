import 'dart:math';

import 'package:collection/collection.dart';
import 'package:draggable_scrollbar/draggable_scrollbar.dart';
import 'package:fluent_ui/fluent_ui.dart' show FluentTheme;
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:momento_booth/models/gallery_group.dart';
import 'package:momento_booth/models/gallery_image.dart';
import 'package:momento_booth/views/base/screen_view_base.dart';
import 'package:momento_booth/views/components/imaging/image_with_loader_fallback.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/components/buttons/photo_booth_button.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/components/text/auto_size_text_and_icon.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/gallery_screen/gallery_screen_controller.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/gallery_screen/gallery_screen_view_model.dart';
import 'package:smooth_scroll_multiplatform/smooth_scroll_multiplatform.dart';

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
                child: Observer(
                  builder: (context) => getFilterBar(),
                ),
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
            height: 1,
          ),
        ),
        const SizedBox(width: 12),
        FilterChoice(sortBy: viewModel.sortBy, onChanged: viewModel.onSortByChanged),
        const SizedBox(width: 20),
        if (viewModel.imageNames == null && viewModel.isFaceRecognitionEnabled)
          OutlinedButton.icon(
            onPressed: controller.onFindMyFace,
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.all(Colors.blue.shade700),
              foregroundColor: WidgetStateProperty.all(Colors.white),
              overlayColor: WidgetStateProperty.all(Colors.blue.shade400),
            ),
            icon: const Icon(LucideIcons.scanFace),
            label: const Text("Find my face"),
          )
        else if (viewModel.imageNames != null)
          OutlinedButton.icon(
            onPressed: controller.clearImageFilter,
            style: ButtonStyle(
              foregroundColor: WidgetStateProperty.all(Colors.white),
              overlayColor: WidgetStateProperty.all(Colors.red.shade900),
              side: WidgetStateProperty.all(const BorderSide(color: Color.fromARGB(255, 255, 117, 117))),
            ),
            icon: const Icon(LucideIcons.funnelX),
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
    return SegmentedButton(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith<Color>(
          (states) {
              if (states.contains(WidgetState.selected)) {
                return FluentTheme.of(context).accentColor;
              }
              return Colors.transparent;
            },
        ),
        iconColor: WidgetStateProperty.all(Colors.white),
        foregroundColor: WidgetStateProperty.all(Colors.white)
      ),
      showSelectedIcon: false,
      segments: const [
        ButtonSegment(
          value: SortBy.time,
          label: Text('Time'),
          icon: Icon(LucideIcons.clock),
        ),
        ButtonSegment(
          value: SortBy.people,
          label: Text('Group size'),
          icon: Icon(LucideIcons.users),
        ),
      ],
      selected: {sortBy},
      onSelectionChanged: (newSelection) {
        // By default there is only a single segment that can be
        // selected at one time, so its value is always the first
        // item in the selected set.
        onChanged(newSelection.first);
      },
    );
  }

}
