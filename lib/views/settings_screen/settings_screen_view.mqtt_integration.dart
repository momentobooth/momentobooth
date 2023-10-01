part of 'settings_screen_view.dart';

Widget _getMqttIntegrationSettings(SettingsScreenViewModel viewModel, SettingsScreenController controller) {
  return FluentSettingsPage(
    title: "Hardware",
    blocks: [
      _getBooleanInput(
        icon: FluentIcons.toggle_border,
        title: "Enable MQTT integration",
        subtitle: "If enabled, the application will publish MQTT messages to the specified broker and will subscribe for commands.\nMore info on the possibilities of MQTT can be found in the documentation.",
        value: () => viewModel.mqttIntegrationEnableSetting,
        onChanged: controller.onMqttIntegrationEnableChanged,
        prefixWidget: const MqttConnectionStateIndicator(),
      ),
      _getTextInput(
        icon: FluentIcons.server,
        title: "MQTT broker address",
        subtitle: "The address of the MQTT broker to connect to.",
        controller: controller.mqttIntegrationHostController,
        onChanged: controller.onMqttIntegrationHostChanged,
      ),
      _getInput(
        icon: FluentIcons.my_network,
        title: "MQTT broker port",
        subtitle: "The port of the MQTT broker to connect to.",
        value: () => viewModel.mqttIntegrationPortSetting,
        onChanged: controller.onMqttIntegrationPortChanged,
      ),
      _getBooleanInput(
        icon: FluentIcons.security_test,
        title: "Use secure connection",
        subtitle: "If enabled, the application will use a secure connection to connect to the MQTT broker.",
        value: () => viewModel.mqttIntegrationSecureSetting,
        onChanged: controller.onMqttIntegrationSecureChanged,
      ),
      // webscoekt
      _getBooleanInput(
        icon: FluentIcons.toggle_border,
        title: "Use WebSocket",
        subtitle: "If enabled, the application will use a WebSocket connection to connect to the MQTT broker.",
        value: () => viewModel.mqttIntegrationUseWebSocketSetting,
        onChanged: controller.onMqttIntegrationUseWebSocketChanged,
      ),
      _getTextInput(
        icon: FluentIcons.user_optional,
        title: "MQTT username",
        subtitle: "The username to use when connecting to the MQTT broker.",
        controller: controller.mqttIntegrationUsernameController,
        onChanged: controller.onMqttIntegrationUsernameChanged,
      ),
      _getTextInput(
        icon: FluentIcons.password_field,
        title: "MQTT password",
        subtitle: "The password to use when connecting to the MQTT broker.",
        controller: controller.mqttIntegrationPasswordController,
        onChanged: controller.onMqttIntegrationPasswordChanged,
      ),
      _getTextInput(
        icon: FluentIcons.remote_application,
        title: "MQTT client ID",
        subtitle: "If enabled, the application will use a custom client ID when connecting to the MQTT broker.",
        controller: controller.mqttIntegrationClientIdController,
        onChanged: controller.onMqttIntegrationClientIdChanged,
      ),
      _getTextInput(
        icon: FluentIcons.chat,
        title: "MQTT root topic",
        subtitle: "The root topic to use when publishing and subscribing to MQTT messages.",
        controller: controller.mqttIntegrationRootTopicController,
        onChanged: controller.onMqttIntegrationRootTopicChanged,
      ),
    ],
  );
}
