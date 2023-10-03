// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

part 'home_assistant_discovery_payload.freezed.dart';
part 'home_assistant_discovery_payload.g.dart';

// ///////////// //
// Root settings //
// ///////////// //

@Freezed(toJson: true)
class HomeAssistantDiscoveryPayload with _$HomeAssistantDiscoveryPayload {

  const HomeAssistantDiscoveryPayload._();

  const factory HomeAssistantDiscoveryPayload.sensor({
    
    @JsonKey(name: 'name') required String name,
    @JsonKey(name: 'state_topic') required String stateTopic,
    @JsonKey(name: 'unique_id') required String uniqueId,
    @JsonKey(name: 'device') required HomeAssistantDevice device,
  }) = HomeAssistantSensorDiscoveryPayload;

}

@Freezed(toJson: true)
class HomeAssistantDevice with _$HomeAssistantDevice {

  const HomeAssistantDevice._();

  const factory HomeAssistantDevice({
    @JsonKey(name: 'identifiers') required List<String> identifiers,
    @JsonKey(name: 'manufacturer') required String manufacturer,
    @JsonKey(name: 'model') required String model,
    @JsonKey(name: 'name') required String name,
    @JsonKey(name: 'sw_version') required String softwareVersion,
  }) = _HomeAssistantDevice;

}
