# Home Assistant integration

When enabled, MomentoBoth can integrate with Home Assistant and install a device that exposes information that can be used in Home Assistant for tracking or automations. The integration provides the following:

- Some general info like the software version (part of the "device")
- Several sensors that mirror the software's statistics (number of captures, prints, etc.)
- An automation trigger based on the capture state (`idle`, `countdown`, `capturing`)
  - This is useful to sync lights with.

This integration uses [Home Assistant's MQTT integration](https://www.home-assistant.io/integrations/mqtt/) and the device will automatically show up if MomentoBooth is connected to your Home Assistant's MQTT server and the integration is enabled.

Additional control features can be used from Home Assistant when the [Control API](./control_API.md) is enabled.
