import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:momento_booth/views/base/screen_view_base.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/components/buttons/photo_booth_button.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/components/text/photo_booth_subtitle.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/components/text/photo_booth_title.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/navigation_screen/navigation_screen_controller.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/navigation_screen/navigation_screen_view_model.dart';

class NavigationScreenView extends ScreenViewBase<NavigationScreenViewModel, NavigationScreenController> {

  const NavigationScreenView({
    required super.viewModel,
    required super.controller,
    required super.contextAccessor,
  });
  
  @override
  Widget get body {
    return Column(
      children: [
        Flexible(
          fit: FlexFit.tight,
          child: Center(
            child: PhotoBoothTitle("What would you like to do?"),
          ),
        ),
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 64),
            child: Row(
              spacing: 32,
              children: [
                Expanded(child: _photoButton),
                Expanded(child: _galleryButton),
              ],
            ),
          ),
        ),
        Flexible(fit: FlexFit.tight, child: _bottomRow),
      ],
    );
  }

  Widget get _photoButton {
    return PhotoBoothButton.action(
      onPressed: controller.onClickPhoto,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 24, 0, 8),
        child: Column(
          spacing: 16,
          children: [
            Expanded(child: FittedBox(child: _iconWithShadow(LucideIcons.camera, 450))),
            AutoSizeText(
              "Take pictures",
              group: controller.autoSizeGroup,
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }

  Widget get _galleryButton {
    return PhotoBoothButton.action(
      onPressed: controller.onClickGallery,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 24, 0, 8),
        child: Column(
          spacing: 16,
          children: [
            Expanded(child: FittedBox(child: _iconWithShadow(LucideIcons.images, 450))),
            AutoSizeText(
              "View gallery",
              group: controller.autoSizeGroup,
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }

  Widget _iconWithShadow(IconData icon, double size) {
    return Icon(
      icon,
      size: size,
      color: const Color(0xE6FFFFFF),
      shadows: [const Shadow(
        color: Color(0x42000000),
        offset: Offset(0, 3),
        blurRadius: 8,
      )],
    );
  }

  Widget get _bottomRow {
    return Padding(
      padding: const EdgeInsets.only(bottom: 32, left: 64, right: 64),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          PhotoBoothButton.action(
            onPressed: controller.onClickLanguage,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _iconWithShadow(LucideIcons.languages, 52),
                const SizedBox(width: 16),
                PhotoBoothSubtitle("Change Language"),
              ],
            ),
          ),
        ],
      ),
    );
  }

}
