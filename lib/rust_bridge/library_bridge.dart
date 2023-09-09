import 'dart:ffi';
import 'dart:io';

import 'package:momento_booth/rust_bridge/library_api.generated.dart';

const _base = 'momento_booth_native_helpers';
final _path = Platform.isWindows ? '$_base.dll' : 'lib$_base.so';
final _dylib = Platform.isIOS || Platform.isMacOS
    ? DynamicLibrary.executable()
    : DynamicLibrary.open(_path);

final rustLibraryApi = MomentoBoothNativeHelpersImpl(_dylib);
