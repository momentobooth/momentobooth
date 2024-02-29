import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dart_casing/dart_casing.dart';
import 'package:intl/intl.dart';
import 'package:loggy/loggy.dart' as loggy;
import 'package:mobx/mobx.dart';
import 'package:momento_booth/exceptions/mqtt_exception.dart';
import 'package:momento_booth/managers/settings_manager.dart';
import 'package:momento_booth/managers/stats_manager.dart';
import 'package:momento_booth/models/capture_state.dart';
import 'package:momento_booth/models/connection_state.dart';
import 'package:momento_booth/models/home_assistant/home_assistant_discovery_payload.dart';
import 'package:momento_booth/models/settings.dart';
import 'package:momento_booth/models/stats.dart';
import 'package:momento_booth/utils/platform_and_app.dart';
import 'package:mqtt5_client/mqtt5_client.dart';
import 'package:mqtt5_client/mqtt5_server_client.dart';
import 'package:synchronized/synchronized.dart';

part 'mqtt_manager.g.dart';

class MqttManager extends _MqttManagerBase with _$MqttManager {

  static final MqttManager instance = MqttManager._internal();

  MqttManager._internal();

}

/// Class containing global state for photos in the app
abstract class _MqttManagerBase with Store {

  final Lock _updateMqttClientInstanceLock = Lock();

  MqttIntegrationSettings? _currentSettings;
  MqttServerClient? _client;

  Map<String, dynamic> _lastPublishedStats = {};
  String _lastPublishedRoute = "";
  CaptureState _lastPublishedCaptureState = CaptureState.idle;
  Settings _settings = SettingsManager.instance.settings;

  @readonly
  ConnectionState _connectionState = ConnectionState.disconnected;

  // //////////////////////////////////// //
  // Initialization and client management //
  // //////////////////////////////////// //

  void initialize() {
    // Respond to settings changes
    autorun((_) {
      MqttIntegrationSettings newMqttSettings = SettingsManager.instance.settings.mqttIntegration;
      _updateMqttClientInstanceLock.synchronized(() async {
        await _recreateClient(newMqttSettings);
      });
    });

    // Publish stats
    autorun((_) {
      Stats stats = StatsManager.instance.stats;
      if (_client != null) _publishStats(stats);
    });
  }

  Future<void> _recreateClient(MqttIntegrationSettings newSettings) async {
    if (newSettings == _currentSettings) return;

    _client?.disconnect();
    _client = null;
    _connectionState = ConnectionState.disconnected;

    if (newSettings.enable) {
      _connectionState = ConnectionState.connecting;
      MqttServerClient client = MqttServerClient.withPort(
        newSettings.host,
        newSettings.clientId,
        newSettings.port,
      )
        ..useWebSocket = newSettings.useWebSocket
        ..secure = newSettings.secure
        ..autoReconnect = true;

      if (!newSettings.verifyCertificate) {
        client.onBadCertificate = (certificate) => true;
      }

      try {
        MqttConnectionStatus? result = await client.connect(newSettings.username, newSettings.password);
        if (result?.state != MqttConnectionState.connected) {
          throw MqttException("Failed to connect to MQTT server: ${result?.reasonCode} ${result?.reasonString}");
        }

        loggy.logInfo("Connected to MQTT server");
        _client = client
          ..onDisconnected = (() => loggy.logInfo("Disconnected from MQTT server"))
          ..onAutoReconnect = (() {
            _connectionState = ConnectionState.connecting;
            loggy.logInfo("Reconnecting to MQTT server");
          })
          ..onAutoReconnected = (() {
            _connectionState = ConnectionState.connected;
            loggy.logInfo("Reconnected to MQTT server");
            _forcePublishAll();
          });

        _connectionState = ConnectionState.connected;
        _forcePublishAll();
        _createSubscriptions();
      } catch (e) {
        loggy.logError("Failed to connect to MQTT server: $e");
      }
    }

    _currentSettings = newSettings;
  }

  // /////////////// //
  // Publish methods //
  // /////////////// //

  void _publish(String topic, String message, {bool retain = false}) {
    if (_client == null) return;

    String rootTopic = SettingsManager.instance.settings.mqttIntegration.rootTopic;
    _client!.publishMessage(
      '$rootTopic/$topic',
      MqttQos.atMostOnce,
      (MqttPayloadBuilder()..addString(message)).payload!,
      retain: retain,
    );
  }

  void _forcePublishAll() {
    _publishStats(StatsManager.instance.stats, true);
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
    if (settings != null) _settings = settings;
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

    String rootTopic = SettingsManager.instance.settings.mqttIntegration.rootTopic;
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
    String rootTopic = SettingsManager.instance.settings.mqttIntegration.rootTopic;
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
            loggy.logWarning("Received unknown published MQTT message: $message");
        }
      } catch (e) {
        loggy.logError("Failed to parse published MQTT message (length: ${message?.payload.length}): $e");
      }
    });

    _subscribeToTopic('update_settings');
  }

  void _subscribeToTopic(String relativeTopic) {
    _client!.subscribe(
      "${SettingsManager.instance.settings.mqttIntegration.rootTopic}/$relativeTopic",
      MqttQos.atMostOnce,
    );

    // TODO: error handling?
  }

  void _onSettingsMessage(String message) {
    loggy.logInfo("Received settings update from MQTT");
    Settings settings = Settings.fromJson(jsonDecode(message));
    SettingsManager.instance.updateAndSave(settings.copyWith(
      // Don't copy these settings from MQTT
      mqttIntegration: SettingsManager.instance.settings.mqttIntegration,
    ));
    loggy.logInfo("Loaded settings data from MQTT");
  }

  // ////////////////////////// //
  // Home Assistant integration //
  // ////////////////////////// //

  HomeAssistantDevice get homeAssistantDevice => HomeAssistantDevice(
      identifiers: [SettingsManager.instance.settings.mqttIntegration.homeAssistantComponentId],
      manufacturer: "h3x Software",
      model: "MomentoBooth",
      name: "MomentoBooth instance on ${Platform.localHostname}",
      softwareVersion: '${packageInfo.version} build ${packageInfo.buildNumber}',
    );

  void publishHomeAssistantDiscoveryTopics() {
    if (_client == null || !SettingsManager.instance.settings.mqttIntegration.enableHomeAssistantDiscovery) return;

    String rootTopic = SettingsManager.instance.settings.mqttIntegration.rootTopic;

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
    final String discoveryTopicPrefix = SettingsManager.instance.settings.mqttIntegration.homeAssistantDiscoveryTopicPrefix;
    final String componentId = SettingsManager.instance.settings.mqttIntegration.homeAssistantComponentId;

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
    final String discoveryTopicPrefix = SettingsManager.instance.settings.mqttIntegration.homeAssistantDiscoveryTopicPrefix;
    final String componentId = SettingsManager.instance.settings.mqttIntegration.homeAssistantComponentId;

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
