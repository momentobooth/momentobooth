import 'package:fluent_ui/fluent_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:momento_booth/views/base/screen_view_base.dart';
import 'package:momento_booth/views/components/dialogs/loading_dialog.dart';
import 'package:momento_booth/views/components/imaging/quote_collage.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/components/buttons/photo_booth_button.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/components/text/auto_size_text_and_icon.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/components/text/photo_booth_title.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/post_recording_screen/post_recording_screen_controller.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/post_recording_screen/post_recording_screen_view_model.dart';

class PostRecordingScreenView extends ScreenViewBase<PostRecordingScreenViewModel, PostRecordingScreenController> {

  const PostRecordingScreenView({
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
        Column(
          children: [
            Expanded(
              flex: 2,
              child: Center(child: PhotoBoothTitle("Thanks!")),
            ),
            Center(
              child: Container(
                color: Colors.white,
                padding: EdgeInsetsGeometry.all(16),
                child: FittedBox(
                  child: QuoteCollage(
                    key: controller.collageKey,
                    // decodeCallback: controller.onDecoded,
                  )
                )
              )
            ),
            Flexible(child: SizedBox())
          ],
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 30),
          child: _foregroundElements,
        ),
      ],
    );
  }

    Widget get _foregroundElements {
    return Column(
      children: [
        Expanded(
          flex: 3,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: SizedBox()
              ),
              Flexible(
                child: PhotoBoothButton.navigation(
                  onPressed: controller.onClickNext,
                  child: AutoSizeTextAndIcon(
                    text: localizations.genericDoneButton,
                    rightIcon: LucideIcons.stepForward,
                    autoSizeGroup: controller.navigationButtonGroup,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

}
