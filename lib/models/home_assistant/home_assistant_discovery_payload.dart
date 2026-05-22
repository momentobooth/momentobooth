// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

part 'home_assistant_discovery_payload.freezed.dart';
part 'home_assistant_discovery_payload.g.dart';

// ///////////// //
// Root settings //
// ///////////// //

@Freezed(toJson: true)
sealed class HomeAssistantDiscoveryPayload with _$HomeAssistantDiscoveryPayload {

  const HomeAssistantDiscoveryPayload._();

  const factory HomeAssistantDiscoveryPayload.sensor({
    @JsonKey(name: 'name') required String name,
    @JsonKey(name: 'state_topic') required String stateTopic,
    @JsonKey(name: 'unique_id') required String uniqueId,
    @JsonKey(name: 'device') required HomeAssistantDevice device,
  }) = HomeAssistantSensorDiscoveryPayload;

  const factory HomeAssistantDiscoveryPayload.deviceTrigger({
    @JsonKey(name: 'automation_type') @Default("trigger") String automationType,
    @JsonKey(name: 'payload') required String payload,
    @JsonKey(name: 'topic') required String topic,
    @JsonKey(name: 'type') required String type,
    @JsonKey(name: 'subtype') required String subtype,
    @JsonKey(name: 'device') required HomeAssistantDevice device,
  }) = HomeAssistantDeviceTriggerDiscoveryPayload;

  const factory HomeAssistantDiscoveryPayload.select({
    @JsonKey(name: 'name') required String name,
    @JsonKey(name: 'options') required List<String> options,
    @JsonKey(name: 'state_topic') required String stateTopic,
    @JsonKey(name: 'command_topic') required String commandTopic,
    @JsonKey(name: 'unique_id') required String uniqueId,
    @JsonKey(name: 'device') required HomeAssistantDevice device,
  }) = HomeAssistantSelectDiscoveryPayload;

  const factory HomeAssistantDiscoveryPayload.notify({
    @JsonKey(name: 'name') required String name,
    @JsonKey(name: 'command_topic') required String commandTopic,
    @JsonKey(name: 'unique_id') required String uniqueId,
    @JsonKey(name: 'device') required HomeAssistantDevice device,
  }) = HomeAssistantNotifyDiscoveryPayload;


}

@Freezed(toJson: true)
sealed class HomeAssistantDevice with _$HomeAssistantDevice {

  const HomeAssistantDevice._();

  const factory HomeAssistantDevice({
    @JsonKey(name: 'identifiers') required List<String> identifiers,
    @JsonKey(name: 'manufacturer') required String manufacturer,
    @JsonKey(name: 'model') required String model,
    @JsonKey(name: 'name') required String name,
    @JsonKey(name: 'sw_version') required String softwareVersion,
  }) = _HomeAssistantDevice;

}
