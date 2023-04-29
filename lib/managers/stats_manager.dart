import 'dart:io';

import 'package:loggy/loggy.dart';
import 'package:mobx/mobx.dart';
import 'package:momento_booth/models/stats.dart';
import 'package:path/path.dart' hide context;
import 'package:path_provider/path_provider.dart';
import 'package:toml/toml.dart';

part 'stats_manager.g.dart';

class StatsManager = StatsManagerBase with _$StatsManager;

enum StatFields {
  taps(),
  liveViewFrames(),
  printedPhotos(),
  uploadedPhotos(),
  capturedPhotos(),
  createdSinglePhotos(),
  retakes(),
  createdMultiCapturePhotos(),
}

abstract class StatsManagerBase with Store, UiLoggy {

  @observable
  Stats? _stats;

  @computed
  Stats get stats => _stats!;

  // ////////////// //
  // Initialization //
  // ////////////// //

  StatsManagerBase._internal();

  static final StatsManager instance = StatsManager._internal();

  // /////// //
  // Updates //
  // /////// //

  @action
  void addTap() { _stats = _stats!.copyWith(taps: _stats!.taps+1); }

  @action
  void addLiveViewFrame() { _stats = _stats!.copyWith(liveViewFrames: _stats!.liveViewFrames+1); }

  @action
  void addPrintedPhoto() { _stats = _stats!.copyWith(printedPhotos: _stats!.printedPhotos+1); }

  @action
  void addUploadedPhoto() { _stats = _stats!.copyWith(uploadedPhotos: _stats!.uploadedPhotos+1); }

  @action
  void addCapturedPhoto() { _stats = _stats!.copyWith(capturedPhotos: _stats!.capturedPhotos+1); }

  @action
  void addCreatedSinglePhoto() { _stats = _stats!.copyWith(createdSinglePhotos: _stats!.createdSinglePhotos+1); }

  @action
  void addRetake() { _stats = _stats!.copyWith(retakes: _stats!.retakes+1); }

  @action
  void addCreatedMultiCapturePhoto() { _stats = _stats!.copyWith(createdMultiCapturePhotos: _stats!.createdMultiCapturePhotos+1); }
  
  // /////////// //
  // Persistence //
  // /////////// //

  late File _statsFile;
  static const _fileName = "MomentoBooth_Statistics.toml";

  @action
  Future<void> load() async {
    loggy.debug("Loading statistics");
    await _ensureStatsFileIsSet();

    if (!await _statsFile.exists()) {
      // File does not exist, create new statistics file
      await _save();
      return;
    }

    // File does exist
    String statisticsAsToml = await _statsFile.readAsString();
    TomlDocument statisticsDocument = TomlDocument.parse(statisticsAsToml);
    try {
      var mapWithStringKey = statisticsDocument.toMap().map((key, value) => MapEntry(key, value as int));
      stats =  as ObservableMap<StatFields, int>;
    } catch (_) {
      // Fixme: Failed to parse
      return;
    }
    loggy.debug("Loaded statistics: $stats");
  }

  Future<void> _save() async {
    loggy.debug("Saving statistics");
    await _ensureStatsFileIsSet();

    var mapWithStringKey = stats.map((key, value) => MapEntry(key.toString(), value));
    TomlDocument statisticsDocument = TomlDocument.fromMap(mapWithStringKey);
    String statisticsAsToml = statisticsDocument.toString();
    _statsFile.writeAsString(statisticsAsToml);

    loggy.debug("Saved statistics");
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
