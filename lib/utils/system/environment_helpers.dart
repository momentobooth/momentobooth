// ignore_for_file: non_constant_identifier_names, camel_case_types

import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';

final DynamicLibrary _cRuntimeLib = Platform.isWindows ? DynamicLibrary.open('api-ms-win-crt-environment-l1-1-0.dll') : DynamicLibrary.process();

final _putenv = _cRuntimeLib.lookupFunction<Int32 Function(Pointer<Utf8>), int Function(Pointer<Utf8>)>('_putenv');

int putenv(String e, String v) {
  return using((arena) {
    return _putenv('$e=$v'.toNativeUtf8());
  });
}
