
import 'package:flutter/widgets.dart';
import 'package:momento_booth/main.dart';
import 'package:momento_booth/managers/photos_manager.dart';
import 'package:momento_booth/models/app_action.dart';
import 'package:momento_booth/models/app_action_call.dart';
import 'package:momento_booth/utils/speech_phrases.dart';
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
  String get scopeName => "Collage Maker Screen";

  @override
  List<AppAction> get actions => [
    AppAction(
      name: "select_pictures",
      callback: selectPicturesAPI,
      title: "Select Pictures",
      description: "Choose pictures to include in the collage.",
      inputSchema: '{ "type": "object", "properties": { "selected": { "type": "array", "items": { "type": "integer", "minimum": 1, "maximum": 4 }, "minItems": 0, "maxItems": 4 }}, "description": "The indices of the selected pictures, 1-indexed", "required": ["selected"], "additionalProperties": false }',
      examples: const [
        "select picture {selected}, {selected} and {selected}",
        "select picture {selected} and {second}",
        "select picture {selected}",
        "select the {selected} picture",
        "select the {selected} and {selected} picture",
        "select the {selected}, {selected}, and {selected} picture",
      ],
    ),
    AppAction(
      name: "continue",
      callback: (_) { onContinueTap(); },
      title: "Continue",
      description: "Proceed to the share screen.",
      examples: continuePhrases,
    ),
    AppAction(
      name: "select_all_pictures",
      callback: (_) {
        getIt<PhotosManager>().chosen
          ..clear()
          ..addAll([0, 1, 2, 3]);
      },
      title: "Select All Pictures",
      description: "Select all captured pictures",
      examples: const [
        "select all pictures",
        "select all photos",
        "select all images",
        "select all",
        "all of them",
        "all pictures",
        "use all pictures",
      ],
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
    // Log the action call with the selected pictures as arguments, converting from 0-indexed to 1-indexed.
    // Overwrite any previous select_pictures action to avoid cluttering the action history with multiple select_pictures calls when the user is toggling pictures multiple times.
    registerActionCall(AppActionCall(tool: "select_pictures", arguments: {"selected": getIt<PhotosManager>().chosen.map((index) => index + 1).toList()}), overwriteSameName: true);
  }

  Future<void> onTimeout() async {
    if (getIt<PhotosManager>().chosen.isNotEmpty) {
      await viewModel.generateCollage(collageKey: collageKey);
    }
  }

  Future<void> onContinueTap() async {
    if (getIt<PhotosManager>().chosen.isNotEmpty) {
      registerActionCall(const AppActionCall(tool: "continue"));
      await viewModel.generateCollage(collageKey: collageKey);
      router.go(ShareScreen.defaultRoute);
    }
  }

  /// This is called from the native side when the select_pictures action is called from the actions API.
  /// The selected picture indices are passed in the `selected` field of the params.
  void selectPicturesAPI(Map<String, dynamic> params) {
    List<int> selected = List<int>.from(params["selected"] ?? [])
      .map((index) => index - 1)                    // Convert from 1-indexed to 0-indexed
      .where((index) => index >= 0 && index < 4)    // Ensure indices are within bounds
      .toSet().toList();                            // Remove duplicates
    getIt<PhotosManager>().chosen
      ..clear()
      ..addAll(selected);
    // Log the action call with the selected pictures as arguments
    registerActionCall(AppActionCall(tool: "select_pictures", arguments: {"selected": selected.map((index) => index + 1).toList()}));
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
