import 'package:fluent_ui/fluent_ui.dart';
import 'package:mobx/mobx.dart';

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
