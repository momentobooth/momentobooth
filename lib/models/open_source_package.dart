import 'package:freezed_annotation/freezed_annotation.dart';

part 'open_source_package.freezed.dart';
part 'open_source_package.g.dart';

enum OpenSourceEcosystem { dart, rust, native, flutterEngine, toolchain }

enum OpenSourceUsage { runtime, buildTime }

/// A third-party package, library or tool that MomentoBooth uses, with its license.
@freezed
abstract class OpenSourcePackage with _$OpenSourcePackage {

  const factory OpenSourcePackage({
    required String name,
    required OpenSourceEcosystem ecosystem,

    /// Whether the package ends up in the application or is only used to build it.
    required OpenSourceUsage usage,

    /// Whether MomentoBooth depends on the package itself, rather than through another package.
    @Default(false) bool isDirect,
    String? version,
    String? description,
    String? url,

    /// The SPDX license expression, e.g. `MIT OR Apache-2.0`. For Dart packages this is a comma-separated list of the detected SPDX identifiers instead, as the license files do not state how multiple licenses combine.
    String? license,

    /// The full license text.
    String? licenseText,
  }) = _OpenSourcePackage;

  factory OpenSourcePackage.fromJson(Map<String, Object?> json) => _$OpenSourcePackageFromJson(json);

}
