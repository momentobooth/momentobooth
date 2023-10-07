part of 'settings_screen_view.dart';

Widget _getMqttIntegrationSettings(SettingsScreenViewModel viewModel, SettingsScreenController controller) {
  return FluentSettingsPage(
    title: "MQTT integration",
    blocks: [
      _getBooleanInput(
        icon: FluentIcons.toggle_border,
        title: "Enable MQTT integration",
        subtitle: "If enabled, the application will publish MQTT messages to the specified broker and will subscribe for commands.\nMore info on the possibilities of MQTT can be found in the documentation.",
        value: () => viewModel.mqttIntegrationEnableSetting,
        onChanged: controller.onMqttIntegrationEnableChanged,
        prefixWidget: const MqttConnectionStateIndicator(),
      ),
      _getConnectionBlock(viewModel, controller),
      _getClientBlock(viewModel, controller),
      _getHomeAssistantBlock(viewModel, controller),
    ],
  );
}

Widget _getConnectionBlock(SettingsScreenViewModel viewModel, SettingsScreenController controller) {
  return FluentSettingsBlock(
    title: "Connection",
    settings: [
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
      _getBooleanInput(
        icon: FluentIcons.security_test,
        title: "Verify server certificate",
        subtitle: "If enabled and a secure connection is used, the application will verify the server certificate against the trusted certificates on the device.",
        value: () => viewModel.mqttIntegrationVerifyCertificateSetting,
        onChanged: controller.onMqttIntegrationVerifyCertificateChanged,
      ),
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
      _getPasswordInput(
        icon: FluentIcons.password_field,
        title: "MQTT password",
        subtitle: "The password to use when connecting to the MQTT broker.",
        controller: controller.mqttIntegrationPasswordController,
        onChanged: controller.onMqttIntegrationPasswordChanged,
      ),
    ],
  );
}

Widget _getClientBlock(SettingsScreenViewModel viewModel, SettingsScreenController controller) {
  return FluentSettingsBlock(
    title: "Client",
    settings: [
      _getTextInput(
        icon: FluentIcons.remote_application,
        title: "MQTT client ID",
        subtitle: "The identifier for this MQTT client.",
        controller: controller.mqttIntegrationClientIdController,
        onChanged: controller.onMqttIntegrationClientIdChanged,
      ),
      _getTextInput(
        icon: FluentIcons.chat,
        title: "MQTT root topic",
        subtitle: "The root topic to use when publishing and subscribing to MQTT messages. You might want to add some unique identifier to avoid conflicts with other instances of Momento Booth on the same MQTT broker.",
        controller: controller.mqttIntegrationRootTopicController,
        onChanged: controller.onMqttIntegrationRootTopicChanged,
      ),
    ],
  );
}

Widget _getHomeAssistantBlock(SettingsScreenViewModel viewModel, SettingsScreenController controller) {
  return FluentSettingsBlock(
    title: "Home Assistant integration",
    settings: [
      _getBooleanInput(
        icon: FluentIcons.toggle_border,
        title: "Enable Home Assistant integration",
        subtitle: "If enabled, the application will publish the discovery topics for Home Assistant.",
        value: () => viewModel.mqttIntegrationEnableHomeAssistantDiscoverySetting,
        onChanged: controller.onMqttIntegrationEnableHomeAssistantDiscoveryChanged,
      ),
      _getTextInput(
        icon: FluentIcons.chat,
        title: "Discovery topic",
        subtitle: "The discovery topic as configured in Home Assistant. Use the default value if you haven't changed it in Home Assistant.",
        controller: controller.mqttIntegrationHomeAssistantDiscoveryTopicPrefixController,
        onChanged: controller.onMqttIntegrationHomeAssistantDiscoveryTopicPrefixChanged,
      ),
        _getTextInput(
        icon: FluentIcons.device_run,
        title: "Device ID",
        subtitle: "The device ID to use when publishing the discovery topics for Home Assistant.",
        controller: controller.mqttIntegrationHomeAssistantComponentIdController,
        onChanged: controller.onMqttIntegrationHomeAssistantComponentIdChanged,
      ),
    ],
  );
}
