import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_action.freezed.dart';

@freezed
class AppAction with _$AppAction {
  @override
  final String name;
  @override
  final Function(Map<String, dynamic>) callback;

  AppAction({
    required this.name,
    required this.callback,
  });
}
