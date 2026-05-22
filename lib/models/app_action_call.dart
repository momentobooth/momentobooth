import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_action_call.freezed.dart';
part 'app_action_call.g.dart';

@Freezed(toJson: true, fromJson: true)
abstract class AppActionCall with _$AppActionCall {

  const AppActionCall._();

  const factory AppActionCall({
    required String tool,
    @Default({}) Map<String, dynamic> arguments,
  }) = _AppActionCall;

  factory AppActionCall.fromJson(Map<String, dynamic> json) => _$AppActionCallFromJson(json);

}
