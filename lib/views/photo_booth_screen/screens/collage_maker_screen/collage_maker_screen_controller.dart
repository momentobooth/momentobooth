
import 'package:flutter/widgets.dart';
import 'package:momento_booth/main.dart';
import 'package:momento_booth/managers/photos_manager.dart';
import 'package:momento_booth/views/base/screen_controller_base.dart';
import 'package:momento_booth/views/components/imaging/photo_collage.dart';
import 'package:momento_booth/views/photo_booth_screen/notifications/activity_timeout_callback.dart';
import 'package:momento_booth/views/photo_booth_screen/notifications/activity_timeout_callback_cancellation.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/collage_maker_screen/collage_maker_screen_view_model.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/share_screen/share_screen.dart';

class CollageMakerScreenController extends ScreenControllerBase<CollageMakerScreenViewModel> {

  /// Installed callback request to have the collage be generated even if the activity timeout occurs on this screen.
  late final ActivityTimeoutCallback activityTimeoutCallbackRequest;

  /// Global key to create a snapshot of the [PhotoCollage] widget.
  final GlobalKey<PhotoCollageState> collageKey = GlobalKey<PhotoCollageState>();

  // //// //
  // Init //
  // //// //

  CollageMakerScreenController({
    required super.viewModel,
    required super.contextAccessor,
  }) {
    activityTimeoutCallbackRequest = ActivityTimeoutCallback(onActivityTimeout: onTimeout);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      activityTimeoutCallbackRequest.dispatch(contextAccessor.buildContext);
    });
  }

  // //////// //
  // Handlers //
  // //////// //

  void onTogglePicture(int image) {
    if (getIt<PhotosManager>().chosen.contains(image)) {
      getIt<PhotosManager>().chosen.remove(image);
    } else {
      getIt<PhotosManager>().chosen.add(image);
    }
  }

  Future<void> onTimeout() async {
    if (getIt<PhotosManager>().chosen.isNotEmpty) {
      await viewModel.generateCollage(collageKey: collageKey);
    }
  }

  Future<void> onContinueTap() async {
    if (getIt<PhotosManager>().chosen.isNotEmpty) {
      await viewModel.generateCollage(collageKey: collageKey);
      router.go(ShareScreen.defaultRoute);
    }
  }

  // ////// //
  // Deinit //
  // ////// //

  @override
  void dispose() {
    ActivityTimeoutCallbackCancellation(onActivityTimeout: onTimeout).dispatch(contextAccessor.buildContext);
    super.dispose();
  }

}
