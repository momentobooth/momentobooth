import 'dart:async';

import 'package:collection/collection.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:mobx/mobx.dart';
import 'package:momento_booth/main.dart';
import 'package:momento_booth/managers/_all.dart';
import 'package:momento_booth/models/_all.dart';
import 'package:momento_booth/models/subsystem.dart';
import 'package:momento_booth/utils/hardware.dart';

part 'notifications_manager.g.dart';

class NotificationsManager = NotificationsManagerBase with _$NotificationsManager;

/// Class containing global state for photos in the app
abstract class NotificationsManagerBase with Store {

  static const _printerStatusCheckPeriod = Duration(seconds: 5);

  @observable
  ObservableList<InfoBar> notifications = ObservableList<InfoBar>();

  void initialize() {
    Timer.periodic(_printerStatusCheckPeriod, (_) => _statusCheck());
  }

  Future<void> _statusCheck() async {
    // The printer status check must be done before clearing as it is async and we don't want the notifications to blink.
    final printerNotifications = await _printerStatusCheck();
    notifications
      ..clear()
      ..addAll(printerNotifications)
      ..addAll(_subSystemStatusCheck())
      ..addAll(_externalSystemsStatusCheck())
      // Sort notifications by severity, so that errors are shown first, then warnings, then info.
      ..sort((a, b) {
        if (a.severity == b.severity) {
          return 0;
        }
        return a.severity.index > b.severity.index ? -1 : 1;
      });
  }

  Future<List<InfoBar>> _printerStatusCheck() async {
    final printerNotifications = List<InfoBar>.empty(growable: true);
    final printerNames = getIt<SettingsManager>().settings.hardware.flutterPrintingPrinterNames;
    final printersStatus = await compute(checkPrintersStatus, printerNames);
    printersStatus.forEachIndexed((index, element) {
      final hasErrorNotification = InfoBar.warning(title: const Text("Printer error"), content: Text("Printer ${index+1} has an error."));
      final paperOutNotification = InfoBar.warning(title: const Text("Printer out of paper"), content: Text("Printer ${index+1} is out of paper."));
      final longQueueNotification = InfoBar.info(title: const Text("Long printing queue"), content: Text("Printer ${index+1} has a long queue (${element.jobs} jobs). It might take a while for your print to appear."));
      if (element.jobs >= getIt<SettingsManager>().settings.hardware.printerQueueWarningThreshold) {
        printerNotifications.add(longQueueNotification);
      }
      if (element.hasError) {
        printerNotifications.add(hasErrorNotification);
      }
      if (element.paperOut) {
        printerNotifications.add(paperOutNotification);
      }
    });
    return printerNotifications;
  }

  List<InfoBar> _subSystemStatusCheck() {
    final systemNotifications = List<InfoBar>.empty(growable: true);
    for (var element in getIt<ObservableList<Subsystem>>()) {
      final status = element.subsystemStatus;
      final name = element.subsystemName;
      switch (status) {
        case SubsystemStatusError():
          systemNotifications.add(InfoBar.error(
            title: Text("$name error"),
            content: Text("Subsystem $name has an error: ${status.message}"),
          ));
        case SubsystemStatusWarning():
          systemNotifications.add(InfoBar.warning(
            title: Text("$name warning"),
            content: Text("Subsystem $name has a warning: ${status.message}"),
          ));
        default:
          break;
      }
    }
    return systemNotifications;
  }

  List<InfoBar> _externalSystemsStatusCheck() {
    final systemNotifications = List<InfoBar>.empty(growable: true);
    for (var element in getIt<ExternalSystemStatusManager>().systems) {
      final status = element.isHealthy;
      final severity = element.check.severity;
      final name = element.check.name;
      switch (status) {
        case SubsystemStatusError():
          systemNotifications.add(InfoBar.error(
            title: Text("$name unavailable"),
            content: Text("External service \"$name\" is unavailable: ${status.message}"),
          ));
        case SubsystemStatusWarning():
        // We don't show info severity notifications.
          if (severity == ExternalSystemCheckSeverity.warning) {
            systemNotifications.add(InfoBar.warning(
              title: Text("$name unavailable"),
              content: Text("External service \"$name\" is unavailable: ${status.message}"),
            ));
          }
        default:
          break;
      }
    }
    return systemNotifications;
  }

}
