part of '../settings_screen_view.dart';

Widget _getMqttIntegrationSettings(SettingsScreenViewModel viewModel, SettingsScreenController controller) {
  return SettingsPage(
    title: "MQTT integration",
    blocks: [
      SettingsToggleTile(
        icon: LucideIcons.workflow,
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
  return SettingsSection(
    title: "Connection",
    settings: [
      SettingsTextEditTile(
        icon: LucideIcons.server,
        title: "MQTT broker address",
        subtitle: "The address of the MQTT broker to connect to.",
        controller: controller.mqttIntegrationHostController,
        onFinishedEditing: controller.onMqttIntegrationHostChanged,
      ),
      SettingsNumberEditTile(
        icon: LucideIcons.network,
        title: "MQTT broker port",
        subtitle: "The port of the MQTT broker to connect to.",
        value: () => viewModel.mqttIntegrationPortSetting,
        onFinishedEditing: controller.onMqttIntegrationPortChanged,
      ),
      SettingsToggleTile(
        icon: LucideIcons.network,
        title: "Use secure connection",
        subtitle: "If enabled, the application will use a secure connection to connect to the MQTT broker.",
        value: () => viewModel.mqttIntegrationSecureSetting,
        onChanged: controller.onMqttIntegrationSecureChanged,
      ),
      SettingsToggleTile(
        icon: LucideIcons.network,
        title: "Verify server certificate",
        subtitle: "If enabled and a secure connection is used, the application will verify the server certificate against the trusted certificates on the device.",
        value: () => viewModel.mqttIntegrationVerifyCertificateSetting,
        onChanged: controller.onMqttIntegrationVerifyCertificateChanged,
      ),
      SettingsToggleTile(
        icon: LucideIcons.network,
        title: "Use WebSocket",
        subtitle: "If enabled, the application will use a WebSocket connection to connect to the MQTT broker.",
        value: () => viewModel.mqttIntegrationUseWebSocketSetting,
        onChanged: controller.onMqttIntegrationUseWebSocketChanged,
      ),
      SettingsTextEditTile(
        icon: LucideIcons.user,
        title: "MQTT username",
        subtitle: "The username to use when connecting to the MQTT broker.",
        controller: controller.mqttIntegrationUsernameController,
        onFinishedEditing: controller.onMqttIntegrationUsernameChanged,
      ),
      SettingsSecretEditTile(
        icon: LucideIcons.squareAsterisk,
        title: "MQTT password",
        subtitle: "The password to use when connecting to the MQTT broker. The password will be stored using encrypted storage.",
        secretStorageKey: mqttPasswordSecretKey,
        onSecretStored: getIt<MqttManager>().notifyPasswordChanged,
      ),
    ],
  );
}

Widget _getClientBlock(SettingsScreenViewModel viewModel, SettingsScreenController controller) {
  return SettingsSection(
    title: "Client",
    settings: [
      SettingsTextEditTile(
        icon: LucideIcons.network,
        title: "MQTT client ID",
        subtitle: "The identifier for this MQTT client.",
        controller: controller.mqttIntegrationClientIdController,
        onFinishedEditing: controller.onMqttIntegrationClientIdChanged,
      ),
      SettingsTextEditTile(
        icon: LucideIcons.network,
        title: "MQTT root topic",
        subtitle: "The root topic to use when publishing and subscribing to MQTT messages. You might want to add some unique identifier to avoid conflicts with other instances of MomentoBooth on the same MQTT broker.",
        controller: controller.mqttIntegrationRootTopicController,
        onFinishedEditing: controller.onMqttIntegrationRootTopicChanged,
      ),
    ],
  );
}

Widget _getHomeAssistantBlock(SettingsScreenViewModel viewModel, SettingsScreenController controller) {
  return SettingsSection(
    title: "Home Assistant integration",
    settings: [
      SettingsToggleTile(
        icon: LucideIcons.house,
        title: "Enable Home Assistant integration",
        subtitle: "If enabled, the application will publish the discovery topics for Home Assistant.",
        value: () => viewModel.mqttIntegrationEnableHomeAssistantDiscoverySetting,
        onChanged: controller.onMqttIntegrationEnableHomeAssistantDiscoveryChanged,
      ),
      SettingsTextEditTile(
        icon: LucideIcons.network,
        title: "Discovery topic",
        subtitle: "The discovery topic as configured in Home Assistant. Use the default value if you haven't changed it in Home Assistant.",
        controller: controller.mqttIntegrationHomeAssistantDiscoveryTopicPrefixController,
        onFinishedEditing: controller.onMqttIntegrationHomeAssistantDiscoveryTopicPrefixChanged,
      ),
      SettingsTextEditTile(
        icon: LucideIcons.network,
        title: "Device ID",
        subtitle: "The device ID to use when publishing the discovery topics for Home Assistant.",
        controller: controller.mqttIntegrationHomeAssistantComponentIdController,
        onFinishedEditing: controller.onMqttIntegrationHomeAssistantComponentIdChanged,
      ),
    ],
  );
}
