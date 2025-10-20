import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:momento_booth/extensions/build_context_extension.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/gallery_screen/components/filter_choice.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/gallery_screen/gallery_screen_controller.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/gallery_screen/gallery_screen_view_model.dart';

class FilterBar extends StatelessWidget {

  final GalleryScreenViewModel viewModel;
  final GalleryScreenController controller;

  const FilterBar({super.key, required this.viewModel, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          context.localizations.galleryScreenFilterBarOrderByTitle,
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 18, height: 1),
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
            label: Text(context.localizations.galleryScreenFilterBarFindMyFaceButton),
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
            label: Text(context.localizations.galleryScreenFilterBarClearFilterButton),
          ),
      ],
    );
  }

}
