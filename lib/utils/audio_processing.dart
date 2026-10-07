// ignore_for_file: avoid_dynamic_calls

import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:http/http.dart' as http;
import 'package:momento_booth/main.dart';
import 'package:momento_booth/managers/settings_manager.dart';
import 'package:momento_booth/repositories/secrets/secrets_repository.dart';
import 'package:path/path.dart' as path;

Future<File> recordAudio(File file) async {
    final ffmpegArgString = getIt<SettingsManager>().settings.debug.ffmpegArgumentsForRecording;
    final ffmpegArgs = ffmpegArgString.split(';');
    final result = await Process.run('ffmpeg', [... ffmpegArgs, file.path]);

    if (result.exitCode != 0) {
      throw Exception('Failed to record audio. FFmpeg stderr:\n${result.stderr}');
    }
    return file;
  }

/// An OpenAI-compatible endpoint, resolved from its settings, together with its API key.
typedef OpenAiEndpoint = ({String baseUrl, String? apiKey});

/// Looks up the OpenAI-compatible endpoint with [endpointId] and its API key.
/// Throws when no endpoint with that id exists, e.g. because it has been deleted.
Future<OpenAiEndpoint> resolveOpenAiEndpoint(String endpointId, String purpose) async {
  final endpoint = getIt<SettingsManager>().settings.debug.openAiEndpoints.firstWhereOrNull((e) => e.id == endpointId);
  if (endpoint == null) {
    throw Exception('No OpenAI-compatible endpoint selected for $purpose, or the selected endpoint no longer exists.');
  }
  final apiKey = await getIt<SecretsRepository>().getSecret(openAiEndpointSecretKey(endpoint.id));
  return (baseUrl: endpoint.baseUrl, apiKey: apiKey);
}

Uri _endpointUri(OpenAiEndpoint endpoint, String route) {
  final baseUrl = endpoint.baseUrl.replaceAll(RegExp(r'/+$'), '');
  return Uri.parse('$baseUrl/$route');
}

/// Endpoints without an API key (e.g. a local server) are called without an Authorization header.
Map<String, String> _authHeaders(OpenAiEndpoint endpoint) {
  final apiKey = endpoint.apiKey;
  return apiKey == null || apiKey.isEmpty ? {} : {'Authorization': 'Bearer $apiKey'};
}

Future<String> processAudio(File audioFile, Directory videoDir) async {
  final debugSettings = getIt<SettingsManager>().settings.debug;

  final transcriptionEndpoint = await resolveOpenAiEndpoint(debugSettings.transcriptionEndpointId, 'transcription');
  final transcript = await transcribeAudio(audioFile, transcriptionEndpoint);
  await File(path.join(videoDir.path, "transcript.txt")).writeAsString(transcript);

  final summaryEndpoint = await resolveOpenAiEndpoint(debugSettings.summaryEndpointId, 'summarization');
  final summary = await summarizeTranscript(transcript, summaryEndpoint);
  await File(path.join(videoDir.path, "summary.txt")).writeAsString(summary);

  return summary;
}

Future<String> transcribeAudio(File audioFile, OpenAiEndpoint endpoint) async {
  final uri = _endpointUri(endpoint, 'audio/transcriptions');
  final request = http.MultipartRequest('POST', uri)
    ..headers.addAll(_authHeaders(endpoint))
    ..files.add(await http.MultipartFile.fromPath('file', audioFile.path))
    ..fields['model'] = getIt<SettingsManager>().settings.debug.transcriptionModel;

  final streamed = await request.send();
  final response = await http.Response.fromStream(streamed);

  if (response.statusCode == 200) {
    return jsonDecode(response.body)['text'];
  } else {
    throw Exception('Transcription failed: ${response.body}');
  }
}

Future<String> summarizeTranscript(String transcript, OpenAiEndpoint endpoint) async {
  final uri = _endpointUri(endpoint, 'chat/completions');
  final headers = {
    'Content-Type': 'application/json',
    ..._authHeaders(endpoint),
  };

  final model = getIt<SettingsManager>().settings.debug.llmModel;
  final prompt = getIt<SettingsManager>().settings.debug.textSummaryPrompt;

  final body = jsonEncode({
    'model': model,
    'messages': [
      {
        'role': 'user',
        'content': '$prompt\n$transcript'
      }
    ],
    'temperature': 0.5,
  });

  final response = await http.post(uri, headers: headers, body: body);

  if (response.statusCode == 200) {
    return jsonDecode(response.body)['choices'][0]['message']['content'];
  } else {
    throw Exception('Summary failed: ${response.body}');
  }
}
