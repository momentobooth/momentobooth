import 'dart:io';
import 'dart:typed_data';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:momento_booth/managers/settings_manager.dart';
import 'package:mobx/mobx.dart';
import 'package:momento_booth/utils/hardware.dart';
import 'package:path/path.dart' show basename, join; // Without show mobx complains
import 'package:path_provider/path_provider.dart';

part 'notifications_manager.g.dart';

class NotificationsManager = NotificationsManagerBase with _$NotificationsManager;

class Notification {
  String title;
  String content;
  InfoBarSeverity severity;
  Notification(this.title, this.content, this.severity);
}

/// Class containing global state for photos in the app
abstract class NotificationsManagerBase with Store {

  static final NotificationsManagerBase instance = NotificationsManager._internal();

  @observable
  ObservableList<InfoBar> notifications = ObservableList<InfoBar>();

  NotificationsManagerBase._internal();

}
