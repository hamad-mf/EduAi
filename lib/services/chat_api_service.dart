import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

import '../models/chat_entry.dart';

class ChatApiService {
  ChatApiService._();

  static final ChatApiService instance = ChatApiService._();

  static const String _defaultModel = 'gemini-2.5-flash-lite';

  String? _apiKey;
  String? _model;
  bool _configLoaded = false;
  String? _configDebugMessage;

  bool get isConfigured => (_apiKey ?? '').trim().isNotEmpty;
  String? get configDebugMessage => _configDebugMessage;

  Future<void> loadConfig({bool forceRefresh = false}) async {
    if (_configLoaded && !forceRefresh) {
      return;
    }

    _apiKey = '';
    _model = '';
    _configDebugMessage = null;

    DocumentSnapshot<Map<String, dynamic>> doc;
    try {
      doc = await FirebaseFirestore.instance
          .collection('app_config')
          .doc('gemini')
          .get(const GetOptions(source: Source.server));
    } on FirebaseException catch (error) {
      _configDebugMessage =
          'Firestore read failed (${error.code}). Check rules/project.';
      throw Exception(
        'Could not read Firestore app_config/gemini (${error.code}). '
        'Check rules and login.',
      );
    }

    if (!doc.exists) {
      _configLoaded = true;
      _configDebugMessage =
          'Document not found at app_config/gemini in current Firebase project.';
      return;
    }

    final Map<String, dynamic>? data = doc.data();
    if (data == null) {
      _configLoaded = true;
      _configDebugMessage = 'Document exists but contains no fields.';
      return;
    }

    _apiKey = _readStringField(data, const <String>[
      'apiKey',
      'api_key',
      'apikey',
      'geminiApiKey',
    ]);
    _model = _readStringField(data, const <String>['model', 'geminiModel']);

    if ((_apiKey ?? '').isEmpty) {
      _configDebugMessage =
          'apiKey field missing/empty. Found fields: ${data.keys.join(', ')}';
    }
    _configLoaded = true;
  }

  String _readStringField(Map<String, dynamic> data, List<String> keys) {
    for (final String key in keys) {
      final dynamic value = data[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }

    for (final MapEntry<String, dynamic> entry in data.entries) {
      final String normalized = entry.key.toLowerCase().replaceAll('_', '');
      for (final String key in keys) {
        final String keyNormalized = key.toLowerCase().replaceAll('_', '');
        if (normalized == keyNormalized &&
            entry.value is String &&
            (entry.value as String).trim().isNotEmpty) {
          return (entry.value as String).trim();
        }
      }
    }
    return '';
  }

  Future<String> ask(
    String prompt, {
    List<ChatEntry> history = const <ChatEntry>[],
    String? studyMaterialContext,
    bool answerOnlyFromMaterials = false,
    bool includeModelHistory = true,
  }) async {
    await loadConfig();

    if (!isConfigured) {
      throw Exception(
        'Gemini API key missing in Firestore: app_config/gemini (apiKey).',
      );
    }

    final String model = _model!.isEmpty ? _defaultModel : _model!;
    final Uri uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/'
      '$model:generateContent?key=$_apiKey',
    );

    final List<Map<String, dynamic>> historyContents = <Map<String, dynamic>>[
      ...history.expand((ChatEntry entry) sync* {
        yield <String, dynamic>{
          'role': 'user',
          'parts': <Map<String, dynamic>>[
            <String, dynamic>{'text': entry.userMessage},
          ],
        };
        if (includeModelHistory) {
          yield <String, dynamic>{
            'role': 'model',
            'parts': <Map<String, dynamic>>[
              <String, dynamic>{'text': entry.aiReply},
            ],
          };
        }
      }),
    ];

    final List<Map<String, dynamic>> contents = <Map<String, dynamic>>[
      ...historyContents,
      if (answerOnlyFromMaterials &&
          (studyMaterialContext ?? '').trim().isNotEmpty)
        <String, dynamic>{
          'role': 'user',
          'parts': <Map<String, dynamic>>[
            <String, dynamic>{
              'text':
                  'Study material context for this chat:\n\n${studyMaterialContext!.trim()}',
            },
          ],
        },
      <String, dynamic>{
        'role': 'user',
        'parts': <Map<String, dynamic>>[
          <String, dynamic>{'text': prompt},
        ],
      },
    ];

    final String strictInstruction =
        'You are an academic tutor for school students. '
        'Give clear, factual, step-by-step answers in simple English. '
        'When user asks follow-up like "more detail", continue the same topic from chat history. '
        'Avoid vague filler. Use short headings or bullet points when helpful. '
        'If user asks to list modules/points/topics, scan the full provided context and list all items found, not just the first one. '
        'If multiple modules are present, return a numbered complete list. '
        'Answer strictly from provided study material context only. '
        'If the answer is not present in the context, reply exactly: '
        '"I could not find this in your selected study materials. '
        'Please select relevant notes or ask your teacher to add this topic."';

    final String normalInstruction =
        'You are a helpful tutor for students. '
        'Answer clearly in simple English with direct, useful explanation. '
        'You can answer general questions not related to study materials. '
        'For real-time questions (weather, live scores, live prices), say you do not have live data and suggest checking a live source. '
        'Do not claim your function is limited to study materials when strict mode is off.';

    final Map<String, dynamic> payload = <String, dynamic>{
      'system_instruction': <String, dynamic>{
        'parts': <Map<String, dynamic>>[
          <String, dynamic>{
            'text': answerOnlyFromMaterials
                ? strictInstruction
                : normalInstruction,
          },
        ],
      },
      'contents': contents,
      'generationConfig': <String, dynamic>{
        'temperature': answerOnlyFromMaterials ? 0.2 : 0.35,
        'maxOutputTokens': answerOnlyFromMaterials ? 1400 : 900,
      },
    };

    http.Response response;
    try {
      response = await http
          .post(
            uri,
            headers: <String, String>{'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 30));
    } catch (_) {
      throw Exception(
        'Could not connect to AI service. Check internet and try again.',
      );
    }

    if (response.statusCode < 200 || response.statusCode > 299) {
      throw Exception(_buildFriendlyApiError(response));
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
    return _normalizeReply(text);
  }

  String _buildFriendlyApiError(http.Response response) {
    final int statusCode = response.statusCode;
    String status = '';
    String message = '';

    try {
      final Map<String, dynamic> decoded =
          jsonDecode(response.body) as Map<String, dynamic>;
      final Map<String, dynamic> error =
          decoded['error'] as Map<String, dynamic>? ?? <String, dynamic>{};
      status = (error['status'] as String? ?? '').trim();
      message = (error['message'] as String? ?? '').trim();
    } catch (_) {
      message = response.body.trim();
    }

    final String lower = '$status $message'.toLowerCase();

    if (statusCode == 429 ||
        lower.contains('resource_exhausted') ||
        lower.contains('quota')) {
      return 'Daily Gemini free quota reached. Try again later or use another API key.';
    }

    if (statusCode == 401 ||
        statusCode == 403 ||
        lower.contains('api key') ||
        lower.contains('permission denied')) {
      return 'Gemini API key is invalid or restricted. Update Firestore app_config/gemini.';
    }

    if (statusCode >= 500) {
      return 'Gemini service is temporarily unavailable. Try again in a few minutes.';
    }

    if (message.isNotEmpty) {
      final String oneLine = message.replaceAll(RegExp(r'\s+'), ' ').trim();
      return oneLine.length > 160 ? '${oneLine.substring(0, 160)}...' : oneLine;
    }

    return 'Chat request failed (HTTP $statusCode).';
  }

  String _normalizeReply(String text) {
    return text
        .replaceAll('**', '')
        .replaceAll('`', '')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
  }
}
