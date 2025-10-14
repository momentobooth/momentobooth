import 'package:fluent_ui/fluent_ui.dart' show FluentTheme;
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:momento_booth/extensions/build_context_extension.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/gallery_screen/gallery_screen_view.dart';

class FilterChoice extends StatelessWidget {

  final SortBy sortBy;
  final ValueChanged<SortBy> onChanged;

  const FilterChoice({super.key, required this.sortBy, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SegmentedButton(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.selected)) {
            return FluentTheme.of(context).accentColor;
          }
          return Colors.transparent;
        }),
        iconColor: WidgetStateProperty.all(Colors.white),
        foregroundColor: WidgetStateProperty.all(Colors.white),
      ),
      showSelectedIcon: false,
      segments: [
        ButtonSegment(
          value: SortBy.time,
          label: Text(context.localizations.galleryScreenFilterBarOrderByTime),
          icon: Icon(LucideIcons.clock),
        ),
        ButtonSegment(
          value: SortBy.people,
          label: Text(context.localizations.galleryScreenFilterBarOrderByGroupSize),
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
