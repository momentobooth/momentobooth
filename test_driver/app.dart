// Debug entrypoint that lets tools drive the running app, for example the Dart MCP server used by coding agents.
//
// Run with: fvm flutter run -d windows -t test_driver/app.dart --dart-entrypoint-args="--data-dir=.dev-data" --print-dtd
// See "Driving the running app from agents and tools" in documentation/src/dev_setup.md.
//
// The Flutter Driver extension adds the `ext.flutter.driver` service extension (tap, enter text, wait for widgets, and
// so on). It must be enabled before `main` initializes its own binding. It also replaces text input by an emulation, so
// real keyboard input into text fields does not work in this build; use the `set_text_entry_emulation` command to
// switch it off when typing by hand.

import 'package:flutter_driver/driver_extension.dart';
import 'package:momento_booth/main.dart' as app;

void main(List<String> arguments) {
  enableFlutterDriverExtension();
  app.main(arguments);
}
