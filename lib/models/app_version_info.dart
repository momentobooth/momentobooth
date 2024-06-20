
import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_version_info.freezed.dart';

@freezed
abstract class AppVersionInfo with _$AppVersionInfo {

  const AppVersionInfo._();

  const factory AppVersionInfo({
    required String appVersion,
    required String flutterVersion,
    required String rustVersion,
    required String rustTarget,
  }) = _AppVersionInfo;

}
