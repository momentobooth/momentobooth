import 'dart:async';

import 'package:mobx/mobx.dart';
import 'package:momento_booth/main.dart';
import 'package:momento_booth/models/settings.dart';
import 'package:momento_booth/models/stats.dart';
import 'package:momento_booth/models/subsystem_status.dart';
import 'package:momento_booth/repositories/serializable/serializable_repository.dart';
import 'package:momento_booth/utils/logger.dart';
import 'package:momento_booth/utils/subsystem.dart';

part 'stats_manager.g.dart';

class StatsManager = StatsManagerBase with _$StatsManager;

abstract class StatsManagerBase with Store, Logger, Subsystem {

  @readonly
  late Stats _stats;

  @override
  Future<SubsystemStatus> initialize() async {
    SerialiableRepository<Stats> statsRepository = getIt<SerialiableRepository<Stats>>();
    SubsystemStatus status;

    try {
      bool hasExistingStats = await statsRepository.hasExistingData();

      if (!hasExistingStats) {
        _stats = const Stats();
        status = const SubsystemStatus.ok(
          message: "No existing settings found, a new settings file has been created.",
        );
      } else {
        _stats = await statsRepository.get();
        status = const SubsystemStatus.ok();
      }
    } catch (e) {
      _stats = const Stats();
      status = SubsystemStatus.warning(
        message: "Could not read existing stats: $e\n\nThe stats have been cleared. As such the existing stats file will be overwritten.",
      );
    }

    Timer.periodic(statsSaveTimerInterval, (timer) => _save);
    return status;
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

  @action
  void addTap() => _stats = _stats.copyWith(taps: _stats.taps + 1);

  @action
  void addPrintedPhoto({PrintSize size = PrintSize.normal}) {
    switch(size) {
      case PrintSize.small:
        _stats = _stats.copyWith(printedPhotos: _stats.printedPhotosSmall + 1);
      case PrintSize.tiny:
        _stats = _stats.copyWith(printedPhotos: _stats.printedPhotosTiny + 1);
      case _:
        _stats = _stats.copyWith(printedPhotos: _stats.printedPhotos + 1);
    }
  }

  @action
  void addUploadedPhoto() => _stats = _stats.copyWith(uploadedPhotos: _stats.uploadedPhotos + 1);

  @action
  void addCapturedPhoto() => _stats = _stats.copyWith(capturedPhotos: _stats.capturedPhotos + 1);

  @action
  void addCreatedSinglePhoto() => _stats = _stats.copyWith(createdSinglePhotos: _stats.createdSinglePhotos + 1);

  @action
  void addRetake() => _stats = _stats.copyWith(retakes: _stats.retakes + 1);

  @action
  void addCollageChange() => _stats = _stats.copyWith(retakes: _stats.collageChanges + 1);

  @action
  void addCreatedMultiCapturePhoto() => _stats = _stats.copyWith(createdMultiCapturePhotos: _stats.createdMultiCapturePhotos + 1);

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
