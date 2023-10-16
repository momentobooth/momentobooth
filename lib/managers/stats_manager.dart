import 'dart:async';
import 'dart:io';

import 'package:loggy/loggy.dart';
import 'package:mobx/mobx.dart';
import 'package:momento_booth/models/stats.dart';
import 'package:path/path.dart' hide context;
import 'package:path_provider/path_provider.dart';
import 'package:synchronized/synchronized.dart';
import 'package:toml/toml.dart';

part 'stats_manager.g.dart';

class StatsManager extends _StatsManagerBase with _$StatsManager {

  static final StatsManager instance = StatsManager._internal();

  StatsManager._internal();

}

enum StatFields {
  taps,
  liveViewFrames,
  printedPhotos,
  uploadedPhotos,
  capturedPhotos,
  createdSinglePhotos,
  retakes,
  createdMultiCapturePhotos,
}

abstract class _StatsManagerBase with Store, UiLoggy {

  @readonly
  Stats _stats = const Stats();

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
  void addPrintedPhoto() => _stats = _stats.copyWith(printedPhotos: _stats.printedPhotos + 1);

  @action
  void addUploadedPhoto() => _stats = _stats.copyWith(uploadedPhotos: _stats.uploadedPhotos + 1);

  @action
  void addCapturedPhoto() => _stats = _stats.copyWith(capturedPhotos: _stats.capturedPhotos + 1);

  @action
  void addCreatedSinglePhoto() => _stats = _stats.copyWith(createdSinglePhotos: _stats.createdSinglePhotos + 1);

  @action
  void addRetake() => _stats = _stats.copyWith(retakes: _stats.retakes + 1);

  @action
  void addCreatedMultiCapturePhoto() => _stats = _stats.copyWith(createdMultiCapturePhotos: _stats.createdMultiCapturePhotos + 1);

  // /////////// //
  // Persistence //
  // /////////// //

  late File _statsFile;
  static const _fileName = "Statistics.toml";
  static const _statsSaveTimerInterval = Duration(minutes: 1);
  static final _stateSaveLock = Lock();

  @action
  Future<void> load() async {
    loggy.debug("Loading statistics");
    await _ensureStatsFileIsSet();

    if (!_statsFile.existsSync()) {
      // File does not exist
      _stats = const Stats();
      loggy.warning("Persisted statistics file not found"); 
    } else {
      // File does exist
      loggy.debug("Loading persisted statistics");
      try {
        String statsAsToml = await _statsFile.readAsString();
        TomlDocument statsDocument = TomlDocument.parse(statsAsToml);
        Map<String, dynamic> statsMap = statsDocument.toMap();
        _stats = Stats.fromJson(statsMap);
        loggy.debug("Loaded persisted statistics");
      } catch (_) {
        // Fixme: Failed to parse, ignore for now
        loggy.warning("Persisted statistics could not be loaded"); 
      }
    }

    Timer.periodic(_statsSaveTimerInterval, (timer) => _save());
  }

  Future<void> _save() async {
    await _stateSaveLock.synchronized(() async {
      loggy.debug("Saving statistics");
      await _ensureStatsFileIsSet();

      Map<String, dynamic> mapWithStringKey = _stats.toJson();
      TomlDocument statsDocument = TomlDocument.fromMap(mapWithStringKey);
      String statsAsToml = statsDocument.toString();
      await _statsFile.writeAsString(statsAsToml);

      loggy.debug("Saved statistics");
    });
  }

  // /////// //
  // Helpers //
  // /////// //

  Future<void> _ensureStatsFileIsSet() async {
    // Find path
    Directory storageDirectory = await getApplicationDocumentsDirectory();
    String filePath = join(storageDirectory.path, _fileName);
    _statsFile = File(filePath);
  }

}
