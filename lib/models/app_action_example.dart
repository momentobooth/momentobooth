import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_action_example.freezed.dart';
part 'app_action_example.g.dart';

@Freezed(toJson: true)
abstract class AppActionExample with _$AppActionExample {

  const AppActionExample._();

  const factory AppActionExample({
    required String phrase,
    @Default({}) Map<String, dynamic> arguments,
  }) = _AppActionExample;
}
