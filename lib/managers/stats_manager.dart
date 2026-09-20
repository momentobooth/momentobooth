import 'dart:async';

import 'package:mobx/mobx.dart';
import 'package:momento_booth/main.dart';
import 'package:momento_booth/managers/project_manager.dart';
import 'package:momento_booth/models/settings.dart';
import 'package:momento_booth/models/stats.dart';
import 'package:momento_booth/models/subsystem.dart';
import 'package:momento_booth/repositories/serializable/serializable_repository.dart';
import 'package:momento_booth/utils/logger.dart';

part 'stats_manager.g.dart';

class StatsManager = StatsManagerBase with _$StatsManager;

abstract class StatsManagerBase extends Subsystem with Store, Logger {

  @override
  String subsystemName = "Statistics counter";

  @readonly
  late Stats _stats;

  @override
  Future<void> initialize() async {
    SerialiableRepository<Stats> statsRepository = getIt<SerialiableRepository<Stats>>();

    try {
      bool hasExistingStats = await statsRepository.hasExistingData();

      if (!hasExistingStats) {
        _stats = const Stats();
        reportSubsystemOk(message: "No existing stats data found, a new file will be created.");
      } else {
        _stats = await statsRepository.get();
        reportSubsystemOk();
      }
    } catch (e) {
      _stats = const Stats();
      reportSubsystemWarning(
        message: "Could not read existing stats: $e\n\nThe stats have been cleared. As such the existing stats file will be overwritten.",
      );
    }

    Timer.periodic(statsSaveTimerInterval, (timer) => _save());
  }

  // /////////// //
  // Local stats //
  // /////////// //

  @observable
  int validLiveViewFrames = 0;

  @observable
  int invalidLiveViewFrames = 0;

  @observable
  int duplicateLiveViewFrames = 0;

  // /////// //
  // Updates //
  // /////// //

  /// Applies [mutator] to both the global statistics and, if a project is currently open,
  /// that project's statistics. This keeps call sites to a single method call while still
  /// recording statistics at both the global and per-project level.
  void _apply(Stats Function(Stats s) mutator) {
    _stats = mutator(_stats);
    getIt<ProjectManager>().addToProjectStats(mutator);
  }

  @action
  void addTap() => _apply((s) => s.copyWith(taps: s.taps + 1));

  @action
  void addPrintedPhoto({PrintSize size = PrintSize.normal}) {
    _apply((s) => switch (size) {
      PrintSize.small => s.copyWith(printedPhotosSmall: s.printedPhotosSmall + 1),
      PrintSize.tiny => s.copyWith(printedPhotosTiny: s.printedPhotosTiny + 1),
      _ => s.copyWith(printedPhotos: s.printedPhotos + 1),
    });
  }

  @action
  void addUploadedPhoto() => _apply((s) => s.copyWith(uploadedPhotos: s.uploadedPhotos + 1));

  @action
  void addCapturedPhoto() => _apply((s) => s.copyWith(capturedPhotos: s.capturedPhotos + 1));

  @action
  void addCreatedSinglePhoto() => _apply((s) => s.copyWith(createdSinglePhotos: s.createdSinglePhotos + 1));

  @action
  void addRetake() => _apply((s) => s.copyWith(retakes: s.retakes + 1));

  @action
  void addCollageChange() => _apply((s) => s.copyWith(retakes: s.collageChanges + 1));

  @action
  void addCreatedMultiCapturePhoto() => _apply((s) => s.copyWith(createdMultiCapturePhotos: s.createdMultiCapturePhotos + 1));

  // /////////// //
  // Persistence //
  // /////////// //

  static const statsSaveTimerInterval = Duration(minutes: 1);

  Future<void> _save() async {
    logDebug("Saving statistics");
    await getIt<SerialiableRepository<Stats>>().write(_stats);
    logDebug("Saved statistics");
  }

}

enum StatsField {

  taps,
  liveViewFrames,
  printedPhotos,
  printedPhotosSmall,
  printedPhotosTiny,
  uploadedPhotos,
  capturedPhotos,
  createdSinglePhotos,
  retakes,
  collageChanges,
  createdMultiCapturePhotos,

}
