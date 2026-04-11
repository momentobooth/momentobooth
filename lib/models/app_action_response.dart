import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_action_response.freezed.dart';
part 'app_action_response.g.dart';

@Freezed(toJson: true)
abstract class AppActionResponse with _$AppActionResponse {

  const AppActionResponse._();

  const factory AppActionResponse({
    required bool success,
    required String message,
  }) = _AppActionResponse;
}
