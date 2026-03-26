import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_action.freezed.dart';
part 'app_action.g.dart';

@Freezed(toJson: true)
abstract class AppAction with _$AppAction {

  const AppAction._();

  const factory AppAction({
    required String name,
    required String title,
    required String description,
    @Default([]) List<String> examples,
    @Default('{ "type": "object", "additionalProperties": false }') String inputSchema,
    @JsonKey(includeToJson: false, includeFromJson: false)
    required Function(Map<String, dynamic>) callback,
  }) = _AppAction;
}
