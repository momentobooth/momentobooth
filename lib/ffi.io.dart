import 'dart:ffi';
import 'dart:io';
import 'package:flutter_rust_bridge_example/bridge_definitions.dart';

const base = 'flutter_rust_bridge_example';
final path = Platform.isWindows ? '$base.dll' : 'lib$base.so';
final dylib = Platform.isIOS || Platform.isMacOS
    ? DynamicLibrary.executable()
    : DynamicLibrary.open(path);

final api = FlutterRustBridgeExampleImpl(dylib);
