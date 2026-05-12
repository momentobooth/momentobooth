# Control API

MomentoBooth provides a powerful **Control API** designed for hands-free operation and external automation. By exposing "actions" corresponding to UI elements (buttons, sliders, etc.) within the current "scope" shown in the app, the app can be controlled via external protocols.

A "scope" represents a navigation view shown on screen. This can be a page or a pop-up dialog.

The current implementation utilizes **MQTT** as the transport layer, allowing for deep integration with [smart home systems like Home Assistant](./home_assistant.md) or custom control modules, [such as voice control](#experimental-voice-control).

## MQTT Interface

All communication occurs relative to a `$base_topic` configured in the app settings.

### Topics and Endpoints

| Topic | Data Type | Description |
| --- | --- | --- |
| `actions/list` | `JSON Array` | Current available actions for the visible page/dialog. |
| `actions/execute` | `JSON Object` | Publish here to trigger an action. Requires `tool` and `arguments`. |
| `actions/execute/result` | `JSON Object` | Response from the last executed action. |
| `actions/scopes` | `JSON Array` | The current navigation stack (e.g., `["Gallery", "Print Dialog"]`). |
| `actions/listening` | `Boolean` | `true` if the app is currently accepting external commands. |
| `actions/call_history` | `JSON Map` | Recently executed actions within the retention window. |
| `notify` | `String` | Publish text here to display a toast notification on screen. |

### Home Assistant Integration

Home Assistant entities will be published to use the control API if the [Home Assistant integration](./home_assistant.md) is enabled. The following entities are registered:

* **[MQTT Select Entity](https://www.home-assistant.io/integrations/select.mqtt/)**: Actions appear as a selectable list that updates live based on the app state.
  > [!NOTE]
  > Using the `select` action will only be successfull for actions that do not require arguments.
* **[MQTT Notify Entity](https://www.home-assistant.io/integrations/notify.mqtt/)**: Allows automations to send toast messages directly to the booth display.

## Logic and Interaction

The idea is that an external application can trigger the actions that are available to the user at a specific moment. To provide some feedback to the user as to what is happening and why, toast notifications can be shown with a text provided by the external application.

### The "Listening" State

To prevent interference between physical users and remote controls, the `listening` flag automatically toggles to `false` when:

* The current scope has no defined actions (e.g., Settings or Capture screens).
* **Local Interaction**: A user touches or clicks the screen. Remote control is disabled for a configurable duration after the last touch.

> [!NOTE]
> Toast notifications via the `notify` topic are only displayed when `listening` is `true`. This prevents unwanted distractions when capturing photos or changing settings.

## Data Models

The data models used by the Control API can be found in the [models folder](https://github.com/momentobooth/momentobooth/tree/main/lib/models), but can also easily be understood by inspecting the MQTT output. The core model is `AppAction`, which extends the [Model Context Protocol (MCP)](https://modelcontextprotocol.io/specification/2025-11-25/server/tools#tool) tool definition.

### JSON Examples

**An action definition (item in `actions/list`)**

```json
{
    "name": "set_copies",
    "title": "Set Copies",
    "description": "Sets the number of copies to print.",
    "examples": [
        {
            "phrase": "set copies to {copies:1}",
            "arguments": {
                "copies": 1
            }
        },
        {
            "phrase": "make {copies:three} copies",
            "arguments": {
                "copies": 3
            }
        },
        {
            "phrase": "change copies to {copies:four}",
            "arguments": {
                "copies": 4
            }
        },
        {
            "phrase": "set number of copies to {copies:2}",
            "arguments": {
                "copies": 2
            }
        }
    ],
    "inputSchema": {
        "type": "object",
        "properties": {
            "copies": {
                "type": "integer",
                "description": "The number of copies to print",
                "minimum": 1,
                "maximum": 5
            }
        },
        "required": [
            "copies"
        ],
        "additionalProperties": false
    },
    "inputSchemaExample": "{ \"copies\": integer between 1 and 5 }"
}
```

**Executing an action (`actions/execute`):**

```json
{
  "tool": "set_copies",
  "arguments": {
    "copies": 3
  }
}

```

**Execution Result (`actions/execute/result`):**

```json
{
  "success": true,
  "message": "Copies set to 3"
}

```

## Configuration

The following settings are available in the MomentoBooth configuration:

1. **Enable Control API**: Toggle the MQTT control functionality.
2. **Control Disable Duration**: Seconds to ignore remote commands after a screen touch.
3. **History Retention**: How long (in seconds) to keep executed actions in the `call_history` topic.

## Experimental: Voice Control

For an implementation example using the Control API for voice-activated photo booths, visit the [MomentoVoiceControl](https://github.com/momentobooth/MomentoVoiceControl) repository.