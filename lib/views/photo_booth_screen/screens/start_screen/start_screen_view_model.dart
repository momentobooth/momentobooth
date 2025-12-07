import 'package:mobx/mobx.dart';
import 'package:momento_booth/extensions/build_context_extension.dart';
import 'package:momento_booth/extensions/string_extension.dart';
import 'package:momento_booth/main.dart';
import 'package:momento_booth/managers/photos_manager.dart';
import 'package:momento_booth/managers/project_manager.dart';
import 'package:momento_booth/managers/settings_manager.dart';
import 'package:momento_booth/models/settings.dart';
import 'package:momento_booth/views/base/screen_view_model_base.dart';

part 'start_screen_view_model.g.dart';

class StartScreenViewModel = StartScreenViewModelBase with _$StartScreenViewModel;

abstract class StartScreenViewModelBase extends ScreenViewModelBase with Store {

  @computed
  List<LottieAnimationSettings> get introScreenLottieAnimations => getIt<SettingsManager>().settings.ui.introScreenLottieAnimations;

  @computed
  String? get touchToStartOverrideText => getIt<ProjectManager>().settings.introScreenTouchToStartOverrideText.nullIfEmpty;

  @computed
  bool get showSettingsButton => getIt<SettingsManager>().settings.ui.showSettingsButton;

  @computed
  List<String> get startTexts {
    if (touchToStartOverrideText != null) {
      return [touchToStartOverrideText!];
    } else if (getIt<ProjectManager>().availableLocalizations.isNotEmpty) {
      return getIt<ProjectManager>().availableLocalizations.map((loc) => loc.startScreenTouchToStartButton).toList();
    } else {
      // This should cover both the system default language and when a language override is set in the project.
      return [contextAccessor.buildContext.localizations.startScreenTouchToStartButton];
    }
  }
  
  @computed
  bool get singleStartText => startTexts.length == 1;

  @computed
  bool get showTouchIndicator => getIt<SettingsManager>().settings.ui.showTouchIndicator;

  StartScreenViewModelBase({required super.contextAccessor}) {
    // Remove images in memory
    // Fixme: maybe somewhere else is nicer, but for now it's here.
    getIt<PhotosManager>().reset();
  }

}
