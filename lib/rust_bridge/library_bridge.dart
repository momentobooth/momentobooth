import 'dart:ffi';
import 'dart:io';

import 'package:flutter_rust_bridge_example/rust_bridge/library_api.generated.dart';

const _base = 'flutter_rust_bridge_example';
final _path = Platform.isWindows ? '$_base.dll' : 'lib$_base.so';
final _dylib = Platform.isIOS || Platform.isMacOS
    ? DynamicLibrary.executable()
    : DynamicLibrary.open(_path);

final rustLibraryApi = FlutterRustBridgeExampleImpl(_dylib);
