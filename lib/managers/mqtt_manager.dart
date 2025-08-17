import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dart_casing/dart_casing.dart';
import 'package:intl/intl.dart';
import 'package:mobx/mobx.dart';
import 'package:momento_booth/exceptions/mqtt_exception.dart';
import 'package:momento_booth/main.dart';
import 'package:momento_booth/managers/settings_manager.dart';
import 'package:momento_booth/managers/stats_manager.dart';
import 'package:momento_booth/models/capture_state.dart';
import 'package:momento_booth/models/connection_state.dart';
import 'package:momento_booth/models/home_assistant/home_assistant_discovery_payload.dart';
import 'package:momento_booth/models/settings.dart';
import 'package:momento_booth/models/stats.dart';
import 'package:momento_booth/models/subsystem.dart';
import 'package:momento_booth/repositories/secrets/secrets_repository.dart';
import 'package:momento_booth/utils/environment_info.dart';
import 'package:momento_booth/utils/logger.dart';
import 'package:mqtt5_client/mqtt5_client.dart';
import 'package:mqtt5_client/mqtt5_server_client.dart';
import 'package:synchronized/synchronized.dart';

part 'mqtt_manager.g.dart';

class MqttManager = MqttManagerBase with _$MqttManager;

/// Class containing global state for photos in the app
abstract class MqttManagerBase extends Subsystem with Store, Logger {

  @override
  String subsystemName = "MQTT Manager";

  final Lock _updateMqttClientInstanceLock = Lock();

  MqttIntegrationSettings? _currentSettings;
  MqttServerClient? _client;

  Map<String, dynamic> _lastPublishedStats = {};
  String _lastPublishedRoute = "";
  CaptureState _lastPublishedCaptureState = CaptureState.idle;
  Settings get _settings => getIt<SettingsManager>().settings;

  @readonly
  ConnectionState _connectionState = ConnectionState.disconnected;

  // //////////////////////////////////// //
  // Initialization and client management //
  // //////////////////////////////////// //

  @override
  void initialize() {
    // Respond to settings changes
    autorun((_) {
      MqttIntegrationSettings newMqttSettings = getIt<SettingsManager>().settings.mqttIntegration;
      _updateMqttClientInstanceLock.synchronized(() async {
        await _recreateClient(newMqttSettings, false);
      });
    });

    // Publish stats
    autorun((_) {
      Stats stats = getIt<StatsManager>().stats;
      if (_client != null) _publishStats(stats);
    });
  }

  void notifyPasswordChanged() {
    _updateMqttClientInstanceLock.synchronized(() async {
      MqttIntegrationSettings mqttSettings = getIt<SettingsManager>().settings.mqttIntegration;
      await _recreateClient(mqttSettings, true);
    });
  }

  Future<void> _recreateClient(MqttIntegrationSettings newSettings, bool passwordIsUpdated) async {
    if (newSettings == _currentSettings && !passwordIsUpdated) return;

    _client?.disconnect();
    _client = null;
    _connectionState = ConnectionState.disconnected;

    if (newSettings.enable) {
      _connectionState = ConnectionState.connecting;
      MqttServerClient client = MqttServerClient.withPort(newSettings.host, newSettings.clientId, newSettings.port)
        ..useWebSocket = newSettings.useWebSocket
        ..secure = newSettings.secure
        ..autoReconnect = true;

      if (!newSettings.verifyCertificate) {
        client.onBadCertificate = (certificate) => true;
      }

      try {
        reportSubsystemBusy(message: 'Connecting to MQTT server');
        String password = await getIt<SecretsRepository>().getSecret(mqttPasswordSecretKey) ?? "";
        MqttConnectionStatus? result = await client.connect(newSettings.username, password);
        if (result?.state != MqttConnectionState.connected) {
          throw MqttException("Failed to connect to MQTT server: ${result?.reasonCode} ${result?.reasonString}");
        }

        logInfo("Connected to MQTT server");
        _client = client
          ..onDisconnected = (() {
            _connectionState = ConnectionState.disconnected;
            String errorDescription = "Disconnected from MQTT server";
            reportSubsystemError(message: errorDescription);
            logError("Disconnected from MQTT server");
          })
          ..onAutoReconnect = (() {
            _connectionState = ConnectionState.connecting;
            reportSubsystemBusy(message: 'Connecting to MQTT server');
            logWarning("Reconnecting to MQTT server");
          })
          ..onAutoReconnected = (() {
            _connectionState = ConnectionState.connected;
            reportSubsystemOk();
            logInfo("Reconnected to MQTT server");
            _forcePublishAll();
          });

        _connectionState = ConnectionState.connected;
        reportSubsystemOk();
        _forcePublishAll();
        _createSubscriptions();
      } catch (e, s) {
        String errorDescription = "Failed to connect to MQTT server";
        reportSubsystemError(message: errorDescription, exception: e.toString());
        logError(errorDescription, e, s);
      }
    } else {
      reportSubsystemDisabled();
    }

    _currentSettings = newSettings;
  }

  // /////////////// //
  // Publish methods //
  // /////////////// //

  void _publish(String topic, String message, {bool retain = false}) {
    if (_client == null) return;

    String rootTopic = getIt<SettingsManager>().settings.mqttIntegration.rootTopic;
    _client!.publishMessage(
      '$rootTopic/$topic',
      MqttQos.atMostOnce,
      (MqttPayloadBuilder()..addString(message)).payload!,
      retain: retain,
    );
  }

  void _forcePublishAll() {
    _publishStats(getIt<StatsManager>().stats, true);
    publishScreen();
    publishCaptureState();
    publishSettings();
    _publishAppVersion();
    publishHomeAssistantDiscoveryTopics();
  }

  void _publishStats(Stats stats, [bool force = false]) {
    for (MapEntry<String, dynamic> statsEntry in stats.toJson().entries) {
      if (force || !_lastPublishedStats.containsKey(statsEntry.key) || _lastPublishedStats[statsEntry.key] != statsEntry.value) {
        String statsKeySnakeCase = Casing.snakeCase(statsEntry.key);
        _publish("stats/$statsKeySnakeCase", statsEntry.value.toString(), retain: true);
      }
    }
    _lastPublishedStats = stats.toJson();
  }

  void publishScreen([String? routeName]) {
    if (routeName != null) _lastPublishedRoute = routeName;
    _publish("current_screen", _lastPublishedRoute);
  }

  void publishCaptureState([CaptureState? captureState]) {
    if (captureState != null) _lastPublishedCaptureState = captureState;
    _publish("capture_state", _lastPublishedCaptureState.mqttValue);
  }

  void publishSettings([Settings? settings]) {
    _publish(
      "running_settings",
      jsonEncode(
        _settings.toJson()..["mqttIntegration"] = null,
      ),
    );
  }

  void _publishAppVersion() {
    _publish("app_version", packageInfo.version);
    _publish("app_build", packageInfo.buildNumber);
  }

  void _clearTopic(String topic) {
    if (_client == null) return;

    String rootTopic = getIt<SettingsManager>().settings.mqttIntegration.rootTopic;
    _client!.publishMessage(
      '$rootTopic/$topic',
      MqttQos.atMostOnce,
      MqttPayloadBuilder().payload!,
      retain: true,
    );
  }

  // ///////////// //
  // Subscriptions //
  // ///////////// //

  void _createSubscriptions() {
    String rootTopic = getIt<SettingsManager>().settings.mqttIntegration.rootTopic;
    _client!.updates.listen((messageList) {
      MqttPublishMessage? message;
      try {
        // From example: mqtt5_server_client_secure.dart
        message = messageList[0].payload as MqttPublishMessage;

        switch (message) {
          case MqttPublishMessage(:final variableHeader, :final payload) when variableHeader!.topicName == "$rootTopic/update_settings":
            if (payload.length == 0) return;
            _clearTopic("update_settings");
            _onSettingsMessage(const Utf8Decoder().convert(payload.message!));
          default:
            logWarning("Received unknown published MQTT message: $message");
        }
      } catch (e) {
        logError("Failed to parse published MQTT message (length: ${message?.payload.length}): $e");
      }
    });

    _subscribeToTopic('update_settings');
  }

  void _subscribeToTopic(String relativeTopic) {
    _client!.subscribe(
      "${getIt<SettingsManager>().settings.mqttIntegration.rootTopic}/$relativeTopic",
      MqttQos.atMostOnce,
    );

    // TODO: error handling?
  }

  void _onSettingsMessage(String message) {
    logInfo("Received settings update from MQTT");
    Settings settings = Settings.fromJson(jsonDecode(message));
    getIt<SettingsManager>().updateAndSave(settings.copyWith(
      // Don't copy these settings from MQTT
      mqttIntegration: getIt<SettingsManager>().settings.mqttIntegration,
    ));
    logInfo("Loaded settings data from MQTT");
  }

  // ////////////////////////// //
  // Home Assistant integration //
  // ////////////////////////// //

  HomeAssistantDevice get homeAssistantDevice => HomeAssistantDevice(
      identifiers: [getIt<SettingsManager>().settings.mqttIntegration.homeAssistantComponentId],
      manufacturer: "MomentoBooth",
      model: "Photobooth",
      name: "MomentoBooth instance on ${Platform.localHostname}",
      softwareVersion: '${packageInfo.version} build ${packageInfo.buildNumber}',
    );

  void publishHomeAssistantDiscoveryTopics() {
    if (_client == null || !getIt<SettingsManager>().settings.mqttIntegration.enableHomeAssistantDiscovery) return;

    String rootTopic = getIt<SettingsManager>().settings.mqttIntegration.rootTopic;

    // Stats
    for (MapEntry<String, dynamic> statsEntry in _lastPublishedStats.entries) {
      publishHomeAssistantSensorDiscoveryTopic(
        integrationName: toBeginningOfSentenceCase(Casing.lowerCase(statsEntry.key))!,
        stateTopic: "$rootTopic/stats/${Casing.snakeCase(statsEntry.key)}",
      );
    }

    // Screen
    publishHomeAssistantSensorDiscoveryTopic(
      integrationName: "Current screen",
      stateTopic: "$rootTopic/current_screen",
    );

    // Capture state
    publishHomeAssistantSensorDiscoveryTopic(
      integrationName: "Capture state",
      stateTopic: "$rootTopic/capture_state",
    );
    publishHomeAssistantDeviceTriggerDiscoveryTopic(
      integrationName: "Capture state",
      payload: CaptureState.idle.mqttValue,
      stateTopic: "$rootTopic/capture_state",
    );
    publishHomeAssistantDeviceTriggerDiscoveryTopic(
      integrationName: "Capture state",
      payload: CaptureState.countdown.mqttValue,
      stateTopic: "$rootTopic/capture_state",
    );
    publishHomeAssistantDeviceTriggerDiscoveryTopic(
      integrationName: "Capture state",
      payload: CaptureState.capturing.mqttValue,
      stateTopic: "$rootTopic/capture_state",
    );
  }

  void publishHomeAssistantSensorDiscoveryTopic({required String integrationName, required String stateTopic}) {
    final String discoveryTopicPrefix = getIt<SettingsManager>().settings.mqttIntegration.homeAssistantDiscoveryTopicPrefix;
    final String componentId = getIt<SettingsManager>().settings.mqttIntegration.homeAssistantComponentId;

    _client!.publishMessage(
      '$discoveryTopicPrefix/sensor/$componentId/${Casing.snakeCase(integrationName)}/config',
      MqttQos.atLeastOnce,
      (MqttPayloadBuilder()..addString(jsonEncode(HomeAssistantDiscoveryPayload.sensor(
              name: integrationName,
              stateTopic: stateTopic,
              uniqueId: '${Casing.snakeCase(integrationName)}_$componentId',
              device: homeAssistantDevice,
            ).toJson()))).payload!,
      retain: true,
    );
  }

  void publishHomeAssistantDeviceTriggerDiscoveryTopic({required String integrationName, required String payload, required String stateTopic}) {
    final String discoveryTopicPrefix = getIt<SettingsManager>().settings.mqttIntegration.homeAssistantDiscoveryTopicPrefix;
    final String componentId = getIt<SettingsManager>().settings.mqttIntegration.homeAssistantComponentId;

    final String triggerType = Casing.snakeCase(integrationName);
    final String triggerSubType = Casing.snakeCase(payload);

    _client!.publishMessage(
      '$discoveryTopicPrefix/device_automation/$componentId/${triggerType}_$triggerSubType/config',
      MqttQos.atLeastOnce,
      (MqttPayloadBuilder()
            ..addString(jsonEncode(HomeAssistantDiscoveryPayload.deviceTrigger(
              payload: payload,
              topic: stateTopic,
              type: triggerType,
              subtype: triggerSubType,
              device: homeAssistantDevice,
            ).toJson())))
          .payload!,
      retain: true,
    );
  }

}
