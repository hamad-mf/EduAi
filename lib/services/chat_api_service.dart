import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';

class ChatApiService {
  ChatApiService._();

  static final ChatApiService instance = ChatApiService._();

  bool get isConfigured => !AppConfig.geminiApiKey.startsWith('PASTE_');

  Future<String> ask(String prompt) async {
    if (!isConfigured) {
      throw Exception('Gemini API key is missing in app_config.dart');
    }

    final Uri uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/'
      '${AppConfig.geminiModel}:generateContent?key=${AppConfig.geminiApiKey}',
    );

    final Map<String, dynamic> payload = <String, dynamic>{
      'contents': <Map<String, dynamic>>[
        <String, dynamic>{
          'parts': <Map<String, dynamic>>[
            <String, dynamic>{'text': prompt},
          ],
        },
      ],
      'generationConfig': <String, dynamic>{
        'temperature': 0.5,
        'maxOutputTokens': 350,
      },
    };

    final http.Response response = await http.post(
      uri,
      headers: <String, String>{'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );

    if (response.statusCode < 200 || response.statusCode > 299) {
      throw Exception(
        'Chat API error ${response.statusCode}: ${response.body}',
      );
    }

    final Map<String, dynamic> json =
        jsonDecode(response.body) as Map<String, dynamic>;
    final List<dynamic> candidates =
        json['candidates'] as List<dynamic>? ?? <dynamic>[];
    if (candidates.isEmpty) {
      throw Exception('No response from AI model');
    }

    final Map<String, dynamic> candidate =
        candidates.first as Map<String, dynamic>;
    final Map<String, dynamic> content =
        candidate['content'] as Map<String, dynamic>? ?? <String, dynamic>{};
    final List<dynamic> parts =
        content['parts'] as List<dynamic>? ?? <dynamic>[];
    if (parts.isEmpty) {
      throw Exception('Empty AI response');
    }

    final String text =
        (parts.first as Map<String, dynamic>)['text'] as String? ?? '';
    if (text.trim().isEmpty) {
      throw Exception('Empty AI response');
    }
    return text.trim();
  }
}
