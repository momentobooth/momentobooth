import 'package:win32/win32.dart';

class Win32Exception implements Exception {

  final String message;
  final int win32ErrorCode;

  Win32Exception(this.message, {required this.win32ErrorCode});

  factory Win32Exception.fromLastError(String message) => Win32Exception(message, win32ErrorCode: GetLastError());

  @override
  String toString() => "$message (Error code: 0x${win32ErrorCode.toRadixString(16).padLeft(8, '0')})";

}
