import 'dart:async';

import 'package:grpc/grpc.dart';
import 'package:http/http.dart' as http;
import 'package:mobx/mobx.dart';
import 'package:momento_booth/main.dart';
import 'package:momento_booth/managers/_all.dart';
import 'package:momento_booth/managers/settings_manager.dart';
import 'package:momento_booth/models/settings.dart';
import 'package:momento_booth/models/subsystem.dart';
import 'package:opentelemetry_logging/opentelemetry_logging.dart';

part 'open_telemetry_manager.g.dart';

class OpenTelemetryManager = OpenTelemetryManagerBase with _$OpenTelemetryManager;

abstract class OpenTelemetryManagerBase extends Subsystem with Store {

  @override
  String subsystemName = "Open Telemetry Manager";

  OpenTelemetryLogger? _logger;

  // ////////////// //
  // Initialization //
  // ////////////// //

  @override
  void initialize() {
    // Respond to settings changes
    autorun((_) {
      OpenTelemetrySettings settings = getIt<SettingsManager>().settings.debug.openTelemetry;
      _logger = null;

      if (!settings.enable) {
        reportSubsystemDisabled();
        return;
      }

      Uri uri = Uri.parse(settings.endpoint);

      OpenTelemetryLogger? logger;
      OpenTelemetryBackend backend;
      if (uri.scheme == "grpc" || uri.scheme == "grpcs") {
        if (!uri.hasEmptyPath) {
          reportSubsystemError(message: "gRPC does not support endpoint paths");
          return;
        }

        bool useTls = uri.scheme == "grpcs";
        backend = OpenTelemetryGrpcBackend(
          host: uri.host,
          port: uri.port != 0 ? uri.port : useTls ? 443 : 80,
          options: ChannelOptions(credentials: useTls ? ChannelCredentials.secure() : ChannelCredentials.insecure()),
          callOptions: CallOptions(metadata: settings.headers),
        );
      } else if (uri.scheme == "http" || uri.scheme == "https") {
        backend = OpenTelemetryHttpBackend(
          endpoint: uri,
          client: _DefaultHeadersHttpClient(settings.headers),
          onPostError: ({required body, required statusCode}) async {
            // Check if this logger is still the latest created.
            if (_logger == logger) {
              reportSubsystemError(message: "Logging failed with HTTP status $statusCode: $body");
            }
          },
        );
      } else {
        reportSubsystemError(message: "Endpoint scheme '${uri.scheme}' not supported");
        return;
      }

      _logger = logger = OpenTelemetryLogger(
        backend: backend,
        batchSize: 1,
        flushInterval: const Duration(seconds: 1),
      );
      reportSubsystemBusy(message: "Awaiting confirmation of connection");
    });
  }

  // /////// //
  // Methods //
  // /////// //

}

class _DefaultHeadersHttpClient extends http.BaseClient{
  final Map<String, String> defaultHeaders;
  final http.Client _httpClient = http.Client();

  _DefaultHeadersHttpClient(this.defaultHeaders);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    request.headers.addAll(defaultHeaders);
    return await _httpClient.send(request);
  }
}
