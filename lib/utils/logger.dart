import 'package:momento_booth/main.dart';
import 'package:talker/talker.dart';

mixin Logger {

  static final Talker _talker = getIt<Talker>();

  void logError(dynamic msg, [Object? exception, StackTrace? stackTrace]) {
    _talker.error("[$runtimeType] $msg", exception, stackTrace);
  }

  void logWarning(dynamic msg, [Object? exception, StackTrace? stackTrace]) {
    _talker.warning("[$runtimeType] $msg", exception, stackTrace);
  }

  void logInfo(dynamic msg, [Object? exception, StackTrace? stackTrace]) {
    _talker.info("[$runtimeType] $msg", exception, stackTrace);
  }

  void logDebug(dynamic msg, [Object? exception, StackTrace? stackTrace]) {
    _talker.debug("[$runtimeType] $msg", exception, stackTrace);
  }

}
