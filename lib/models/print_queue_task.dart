import 'package:freezed_annotation/freezed_annotation.dart';

part 'print_queue_task.freezed.dart';

@freezed
class PrintQueueTask with _$PrintQueueTask {

  const PrintQueueTask._();

  const factory PrintQueueTask({
    required String id,
    required String name,
  }) = _PrintQueueTask;

}
