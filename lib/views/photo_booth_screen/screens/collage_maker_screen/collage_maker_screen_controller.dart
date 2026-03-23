
import 'package:flutter/widgets.dart';
import 'package:momento_booth/main.dart';
import 'package:momento_booth/managers/photos_manager.dart';
import 'package:momento_booth/models/app_action.dart';
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

  @override
  List<AppAction> get actions => [
    AppAction(
      name: "select_pictures",
      callback: selectPicturesAPI,
      title: "Select Pictures",
      description: "Choose pictures to include in the collage.",
      inputSchema: '{ "type": "object", "properties": { "selected": { "type": "array", "items": { "type": "integer", "minimum": 0, "maximum": 3 } }, "minItems": 0, "maxItems": 4 }, "description": "The indices of the selected pictures, 0-indexed" }, "required": ["selected"], "additionalProperties": false }'
    ),
    AppAction(
      name: "continue",
      callback: (_) { onContinueTap(); },
      title: "Continue",
      description: "Proceed to the share screen."
    ),
    AppAction(
      name: "select_all_pictures_and_continue",
      callback: (_) {
        getIt<PhotosManager>().chosen
          ..clear()
          ..addAll([0, 1, 2, 3]);
        onContinueTap();
      },
      title: "Select All Pictures and Continue",
      description: "Select all captured pictures, create the collage, and proceed to the share screen."
    ),
  ];

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

  /// This is called from the native side when the select_pictures action is called from the actions API.
  /// The selected picture indices are passed in the `selected` field of the params.
  void selectPicturesAPI(Map<String, dynamic> params) {
    List<int> selected = List<int>.from(params["selected"] ?? []);
    getIt<PhotosManager>().chosen
      ..clear()
      ..addAll(selected);
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
