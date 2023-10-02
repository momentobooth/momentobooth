import 'dart:async';

import 'package:loggy/loggy.dart' as loggy;
import 'package:mobx/mobx.dart';
import 'package:momento_booth/exceptions/mqtt_exception.dart';
import 'package:momento_booth/managers/settings_manager.dart';
import 'package:momento_booth/managers/stats_manager.dart';
import 'package:momento_booth/models/connection_state.dart';
import 'package:momento_booth/models/settings.dart';
import 'package:momento_booth/models/stats.dart';
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
  Map<String, dynamic>? _latestPublishedStats;

  @readonly
  ConnectionState _connectionState = ConnectionState.disconnected;

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

  void _publishStats(Stats stats, [bool force = false]) {
    for (MapEntry<String, dynamic> statsEntry in stats.toJson().entries) {
      if (!force && _latestPublishedStats != null && _latestPublishedStats![statsEntry.key] == statsEntry.value) continue;
      print("Publishing ${statsEntry.key} = ${statsEntry.value}");
      _client!.publishMessage(
        "momento-booth/stats/${statsEntry.key}",
        MqttQos.atMostOnce,
        (MqttPayloadBuilder()..addString(statsEntry.value.toString())).payload!,
        retain: true,
      );
    }
    _latestPublishedStats = stats.toJson();
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
            _publishStats(StatsManager.instance.stats, true);
          });

        _connectionState = ConnectionState.connected;
        _publishStats(StatsManager.instance.stats, true);
      } catch (e) {
        loggy.logError("Failed to connect to MQTT server: $e");
      }
    }

    _currentSettings = newSettings;
  }

}
