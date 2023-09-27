import 'dart:async';

import 'package:loggy/loggy.dart' as loggy;
import 'package:mobx/mobx.dart';
import 'package:momento_booth/managers/settings_manager.dart';
import 'package:momento_booth/managers/stats_manager.dart';
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

  void initialize() {
    autorun((_) {
      // To make sure mobx detects that we are responding to changes to this property
      MqttIntegrationSettings newMqttSettings = SettingsManager.instance.settings.mqttIntegration;
      _updateMqttClientInstanceLock.synchronized(() async {
        await _recreateClient(newMqttSettings);
      });
    });

    autorun((_) {
      Stats stats = StatsManager.instance.stats;
      if (_client != null) {
        for (MapEntry<String, dynamic> statsEntry in stats.toJson().entries) {
          _client!.publishMessage(
            "momento-booth/stats/${statsEntry.key}",
            MqttQos.atLeastOnce,
            MqttPayloadBuilder().addString(statsEntry.value.toString()).payload!,
          );
        }
      }
    });
  }

  Future<void> _recreateClient(MqttIntegrationSettings newSettings) async {
    if (newSettings == _currentSettings) return;

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

    MqttConnectionStatus? result = await client.connect(newSettings.username, newSettings.password);
    if (result?.state != MqttConnectionState.connected) {
      loggy.logError("Failed to connect to MQTT server: ${result?.reasonCode} ${result?.reasonString}");
      return;
    }

    _client = client;
    _currentSettings = newSettings;
  }

}
