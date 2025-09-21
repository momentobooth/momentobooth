import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:mobx/mobx.dart';
import 'package:momento_booth/extensions/get_it_extension.dart';
import 'package:momento_booth/main.dart';
import 'package:momento_booth/managers/_all.dart';
import 'package:momento_booth/models/project_data.dart';
import 'package:momento_booth/models/settings.dart';
import 'package:momento_booth/models/stats.dart';
import 'package:momento_booth/models/subsystem.dart';
import 'package:momento_booth/models/subsystem_status.dart';
import 'package:momento_booth/repositories/_all.dart';
import 'package:momento_booth/src/rust/api/initialization.dart';
import 'package:momento_booth/src/rust/frb_generated.dart';
import 'package:momento_booth/src/rust/models/logging.dart';
import 'package:momento_booth/utils/environment_info.dart';
import 'package:momento_booth/utils/file_utils.dart';
import 'package:path/path.dart' as path;
import 'package:stack_trace/stack_trace.dart';
import 'package:talker/talker.dart';

part 'app_init_manager.g.dart';

class AppInitManager = AppInitManagerBase with _$AppInitManager;

/// This is the 'root' manager of the MomentoBooth Photobooth app.
/// It runs the initialization of the application and is responsible for keeping the status.
abstract class AppInitManagerBase with Store {

  @readonly
  String _status = 'Initializing...';

  @readonly
  bool? _isSucceeded;

  @readonly
  Object? _exception;

  @readonly
  Trace? _stackTrace;

  Future<void> initializeApp() async {
    try {
      _status = 'Creating instances';
      getIt
        ..enableRegisteringMultipleInstancesOfOneType()

        // Log
        ..registerSingleton(Talker(settings: TalkerSettings()))
        ..registerSingleton(ObservableList<Subsystem>())

        // Repositories
        ..registerSingleton<SecretsRepository>(const SecureStorageSecretsRepository())

        // Managers
        ..registerManager(StatsManager())
        ..registerManager(ProjectManager())
        ..registerManager(SfxManager())
        ..registerManager(SettingsManager())
        ..registerManager(WindowManager())
        ..registerManager(LiveViewManager())
        ..registerManager(MqttManager())
        ..registerManager(NotificationsManager())
        ..registerManager(PrintingManager())
        ..registerManager(PhotosManager())
        ..registerManager(ExternalSystemStatusManager())
        ..registerManager(WakelockManager());

      // ////////////////////////// //
      // Helper lib and Environment //
      // ////////////////////////// //

      await _setStatusAndRun('Initializing helper library (FRB)', RustLib.init);
      _initializeLog();
      await _setStatusAndRun('Initializing helper library (custom)', initializeLibrary);
      await _setStatusAndRun('Resolving environment info', initializeEnvironmentInfo);

      // ///////////////// //
      // TOML repositories //
      // ///////////////// //

      _status = 'Instantiating TOML repositories';
      getIt
        ..registerSingleton<SerialiableRepository<Settings>>(
          TomlSerializableRepository(path.join(appDataPath, "Settings.toml"), Settings.fromJson),
        )
        ..registerSingleton<SerialiableRepository<Stats>>(
          TomlSerializableRepository(path.join(appDataPath, "Stats.toml"), Stats.fromJson),
        )
        ..registerSingleton<SerialiableRepository<ProjectsList>>(
          TomlSerializableRepository(path.join(appDataPath, "Projects.toml"), ProjectsList.fromJson),
        );

      // /////////////////////// //
      // Settings and Statistics //
      // /////////////////////// //

      await _setStatusAndRun('Initializing settings manager', getIt<SettingsManager>().initializeSafe);
      await _setStatusAndRun('Creating paths', _createPathsSafe);
      await _setStatusAndRun('Initializing statistics manager', getIt<StatsManager>().initializeSafe);

      // ////////////// //
      // Other managers //
      // ////////////// //

      await _setStatusAndFireAndForget('Initializing project manager', getIt<ProjectManager>().initializeSafe);
      await _setStatusAndFireAndForget('Initializing window manager', getIt<WindowManager>().initializeSafe);
      await _setStatusAndFireAndForget('Initializing live view manager', getIt<LiveViewManager>().initializeSafe);
      await _setStatusAndFireAndForget('Initializing MQTT manager', getIt<MqttManager>().initializeSafe);
      await _setStatusAndFireAndForget('Initializing SFX manager', getIt<SfxManager>().initializeSafe);
      await _setStatusAndFireAndForget('Initializing printing manager', getIt<PrintingManager>().initializeSafe);
      await _setStatusAndFireAndForget('Initializing wakelock manager', getIt<WakelockManager>().initializeSafe);
      await _setStatusAndRun('Initializing notifications manager', getIt<NotificationsManager>().initialize);
      await _setStatusAndRun('Initializing external system status manager', getIt<ExternalSystemStatusManager>().initialize);

      // /////////////////// //
      // Wait for subsystems //
      // /////////////////// //

      _status = 'Waiting for subsystems to be ready';
      Stopwatch stopwatch = Stopwatch()..start();
      while (!_areAllSubsystemsReady && stopwatch.elapsedMilliseconds < 5000) {
        await Future.delayed(Duration(milliseconds: 100));
      }

      _isSucceeded = true;
    } catch (e, s) {
      _exception = e;
      _isSucceeded = false;
      _stackTrace = Trace.from(s).terse;

      Talker? talker = getIt.maybeGet<Talker>();
      if (talker != null) {
        talker.error("Failed to initialize app", e, _stackTrace);
      } else if (kDebugMode) {
        print("Failed to initialize app: $e");
        print("Stack: $_stackTrace");
      }
    }
  }

  bool get _areAllSubsystemsReady {
    return getIt<ObservableList<Subsystem>>().none((s) => s.subsystemStatus is SubsystemStatusInitial || s.subsystemStatus is SubsystemStatusBusy);
  }

  Future<void> _setStatusAndRun(String status, FutureOr<void> Function() func) async {
    _status = status;
    await func();
  }

  Future<void> _setStatusAndFireAndForget(String status, Future<void> Function() func) async {
    _status = status;
    await Future.any([
      func(),
      Future.delayed(const Duration(seconds: 5)),
    ]);
  }

  void _initializeLog() {
    Talker talker = getIt<Talker>();
    initializeLog().listen((msg) {
      LogLevel logLevel = switch (msg.logLevel) {
        Level.error => LogLevel.error,
        Level.warn => LogLevel.warning,
        Level.info => LogLevel.info,
        Level.debug => LogLevel.debug,
        Level.trace => LogLevel.verbose,
      };
      talker.log("Lib: ${msg.lbl} - ${msg.msg}", logLevel: logLevel);
    });
  }

  Future<void> _createPathsSafe() async {
    List<String> paths = [getIt<SettingsManager>().settings.hardware.captureLocation];

    for (String path in paths) {
      createPathSafe(path);
    }
  }

}
