import 'package:freezed_annotation/freezed_annotation.dart';

part 'print_queue_info.freezed.dart';

@freezed
class PrintQueueInfo with _$PrintQueueInfo {

  const PrintQueueInfo._();

  const factory PrintQueueInfo({
    required String id,
    required String name,
    required bool isAvailable,
    bool? isDefault,
  }) = _PrintQueueInfo;

}
