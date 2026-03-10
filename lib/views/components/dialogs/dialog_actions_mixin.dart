import 'package:meta/meta.dart';
import 'package:momento_booth/models/app_action.dart';

mixin DialogActionsMixin {
  @mustBeOverridden
  List<AppAction> get actions => [];
}
