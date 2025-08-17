import 'dart:async';

import 'package:collection/collection.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:mobx/mobx.dart';
import 'package:momento_booth/main.dart';
import 'package:momento_booth/managers/_all.dart';
import 'package:momento_booth/models/subsystem.dart';
import 'package:momento_booth/utils/hardware.dart';
import 'package:momento_booth/utils/logging.dart';

part 'open_telemetry_manager.g.dart';

class OpenTelemetryManager = OpenTelemetryManagerBase with _$OpenTelemetryManager;

/// Class containing global state for photos in the app
abstract class OpenTelemetryManagerBase extends Subsystem with Store, Logger {

  @override
  void initialize() {
  }

}
