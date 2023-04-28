import 'package:mobx/mobx.dart';

part 'stats_manager.g.dart';

class StatsManager = StatsManagerBase with _$StatsManager;

abstract class StatsManagerBase with Store {

  @readonly
  int _taps = 0;

  @readonly
  int _liveViewFrames = 0;

  @readonly
  int _printedPhotos = 0;

  @readonly
  int _uploadedPhotos = 0;

  @readonly
  int _capturedPhotos = 0;

  @readonly
  int _createdSinglePhotos = 0;

  @readonly
  int _retakes = 0;

  @readonly
  int _createdMultiCapturePhotos = 0;

  // ////////////// //
  // Initialization //
  // ////////////// //

  StatsManagerBase._internal();

  static final StatsManager instance = StatsManager._internal();

  // /////// //
  // Updates //
  // /////// //

  @action
  void addTap() => _taps++;

  @action
  void addLiveViewFrame() => _liveViewFrames++;

  @action
  void addPrintedPhoto() => _printedPhotos++;

  @action
  void addUploadedPhoto() => _uploadedPhotos++;

  @action
  void addCapturedPhoto() => _capturedPhotos++;

  @action
  void addCreatedSinglePhoto() => _createdSinglePhotos++;

  @action
  void addRetake() => _retakes++;

  @action
  void addCreatedMultiCapturePhoto() => _createdMultiCapturePhotos++;
  
}
