import 'package:fluent_ui/fluent_ui.dart';
import 'package:mobx/mobx.dart';

part 'notifications_manager.g.dart';

class NotificationsManager extends _NotificationsManagerBase with _$NotificationsManager {

  static final NotificationsManager instance = NotificationsManager._internal();

  NotificationsManager._internal();

}

/// Class containing global state for photos in the app
abstract class _NotificationsManagerBase with Store {

  @observable
  ObservableList<InfoBar> notifications = ObservableList<InfoBar>();

}

class Notification {
  String title;
  String content;
  InfoBarSeverity severity;
  Notification(this.title, this.content, this.severity);
}
