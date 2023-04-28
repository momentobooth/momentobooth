import 'dart:io';

import 'package:loggy/loggy.dart';
import 'package:mobx/mobx.dart';
import 'package:path/path.dart';
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
  
  ObservableMap<StatFields, int> stats = {
    StatFields.taps: 0,
    StatFields.liveViewFrames: 0,
    StatFields.printedPhotos: 0,
    StatFields.uploadedPhotos: 0,
    StatFields.capturedPhotos: 0,
    StatFields.createdSinglePhotos: 0,
    StatFields.retakes: 0,
    StatFields.createdMultiCapturePhotos: 0,
  } as ObservableMap<StatFields, int>;

  // ////////////// //
  // Initialization //
  // ////////////// //

  StatsManagerBase._internal();

  static final StatsManager instance = StatsManager._internal();

  // /////// //
  // Updates //
  // /////// //

  @action
  void addTap() => stats[StatFields.taps] = stats[StatFields.taps]! + 1;

  @action
  void addLiveViewFrame() => stats[StatFields.liveViewFrames] = stats[StatFields.liveViewFrames]! + 1;

  @action
  void addPrintedPhoto() => stats[StatFields.printedPhotos] = stats[StatFields.printedPhotos]! + 1;

  @action
  void addUploadedPhoto() => stats[StatFields.uploadedPhotos] = stats[StatFields.uploadedPhotos]! + 1;

  @action
  void addCapturedPhoto() => stats[StatFields.capturedPhotos] = stats[StatFields.capturedPhotos]! + 1;

  @action
  void addCreatedSinglePhoto() => stats[StatFields.createdSinglePhotos] = stats[StatFields.createdSinglePhotos]! + 1;

  @action
  void addRetake() => stats[StatFields.retakes] = stats[StatFields.retakes]! + 1;

  @action
  void addCreatedMultiCapturePhoto() => stats[StatFields.createdMultiCapturePhotos] = stats[StatFields.createdMultiCapturePhotos]! + 1;
  
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
      stats = statisticsDocument.toMap() as ObservableMap<StatFields, int>;
    } catch (_) {
      // Fixme: Failed to parse
      return;
    }
    loggy.debug("Loaded statistics: $stats");
  }

  Future<void> _save() async {
    loggy.debug("Saving statistics");
    await _ensureStatsFileIsSet();

    TomlDocument statisticsDocument = TomlDocument.fromMap(stats);
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
