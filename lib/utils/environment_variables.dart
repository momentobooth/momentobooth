// ignore_for_file: non_constant_identifier_names, camel_case_types

import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';

final DynamicLibrary msvcrt = Platform.isWindows ? DynamicLibrary.open('msvcrt.dll') : DynamicLibrary.process();


final _putenv_s = msvcrt.lookupFunction<Int32 Function(Pointer<Utf8>, Pointer<Utf8>), int Function(Pointer<Utf8>, Pointer<Utf8>)>('_putenv_s');

int putenv_s(String e, String v) {
  return using((arena) {
    return _putenv_s(e.toNativeUtf8(), v.toNativeUtf8());
  });
}
