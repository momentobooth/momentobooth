import 'package:freezed_annotation/freezed_annotation.dart';

part 'printer_info.freezed.dart';

@freezed
class PrinterInfo with _$PrinterInfo {

  const PrinterInfo._();

  const factory PrinterInfo({
    required String id,
    required String name,
    required bool isAvailable,
    bool? isDefault,
  }) = _PrinterInfo;

}
