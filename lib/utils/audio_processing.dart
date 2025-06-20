import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:momento_booth/main.dart';
import 'package:momento_booth/managers/settings_manager.dart';
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

Future<String> processAudio(File audioFile, Directory videoDir, String openaiApiKey) async {
  final transcript = await transcribeAudio(audioFile, openaiApiKey);
  await File(path.join(videoDir.path, "transcript.txt")).writeAsString(transcript);

  final summary = await summarizeTranscript(transcript, openaiApiKey);
  await File(path.join(videoDir.path, "summary.txt")).writeAsString(summary);

  return summary;
}

Future<String> transcribeAudio(File audioFile, String openaiApiKey) async {
  final uri = Uri.parse('https://api.openai.com/v1/audio/transcriptions');
  final request = http.MultipartRequest('POST', uri)
    ..headers['Authorization'] = 'Bearer $openaiApiKey'
    ..files.add(await http.MultipartFile.fromPath('file', audioFile.path))
    ..fields['model'] = 'whisper-1';

  final streamed = await request.send();
  final response = await http.Response.fromStream(streamed);

  if (response.statusCode == 200) {
    return jsonDecode(response.body)['text'];
  } else {
    throw Exception('Transcription failed: ${response.body}');
  }
}

Future<String> summarizeTranscript(String transcript, String openaiApiKey) async {
  final uri = Uri.parse('https://api.openai.com/v1/chat/completions');
  final headers = {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $openaiApiKey',
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
