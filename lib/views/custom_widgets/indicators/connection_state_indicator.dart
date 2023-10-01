import 'package:flutter/material.dart' hide ConnectionState;
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:momento_booth/managers/mqtt_manager.dart';
import 'package:momento_booth/models/connection_state.dart';

class MqttConnectionStateIndicator extends StatelessWidget {

  const MqttConnectionStateIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) {
        MqttManager manager = MqttManager.instance;
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
                color: manager.connectionState == ConnectionState.connected
                    ? Colors.green
                    : manager.connectionState == ConnectionState.connecting
                        ? Colors.orange
                        : Colors.red,
                shape: BoxShape.circle),
          ),
        );
      },
    );
  }

}
