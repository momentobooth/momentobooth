import 'package:freezed_annotation/freezed_annotation.dart';

part 'notification_request.freezed.dart';
part 'notification_request.g.dart';

@Freezed(toJson: true, fromJson: true)
abstract class NotificationRequest with _$NotificationRequest {

  const NotificationRequest._();

  const factory NotificationRequest({
    required String message,
    @Default(500) int duration,
  }) = _NotificationRequest;

  factory NotificationRequest.fromJson(Map<String, dynamic> json) => _$NotificationRequestFromJson(json);

}
