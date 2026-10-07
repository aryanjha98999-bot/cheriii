import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/app_state.dart';

/// Google Gemini 2.0 Flash integration.
///
/// Free tier limits (as of 2025):
///   • 15 RPM  (requests per minute)
///   • 1 million tokens per day
///   • No cost for gemini-2.0-flash
///
/// Get a free API key at: https://aistudio.google.com/apikey
class GeminiService {
  static const String _model = 'gemini-2.0-flash';
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/$_model';

  // ----------------------------------------------------------------
  // SYSTEM PROMPT — Cheri wellness companion persona
  // ----------------------------------------------------------------

  static String _buildSystemPrompt(AppState state) {
    final user = state.user;
    final phase = state.phase;
    final cycleDay = state.cycleDay;
    final daysUntil = state.daysUntilNextPeriod;
    final entry = state.entryFor(DateTime.now());

    final buffer = StringBuffer();

    buffer.writeln(
      'You are Cherry AI, the warm, knowledgeable and caring wellness companion '
      'inside the Cheri menstrual health app. '
      'You speak in a friendly, empathetic and supportive tone — like a trusted friend '
      'who happens to be a women\'s health expert. '
      'Keep responses concise (2–4 short paragraphs max) unless asked for detail. '
      'Always be warm, never clinical or cold. '
      'You NEVER give specific medical diagnoses. '
      'When symptoms sound serious, always gently suggest consulting a doctor. '
      'Use gentle emojis sparingly (1–2 per reply max). '
      'Avoid markdown formatting like ** or ## — write in plain conversational text.',
    );

    buffer.writeln('\n--- USER CONTEXT (use this to personalise replies) ---');
    buffer.writeln('Name: ${user.name}');
    buffer.writeln('Age: ${user.age}');
    buffer.writeln('Cycle length: ${user.cycleLength} days');
    buffer.writeln('Period length: ${user.periodLength} days');
    buffer.writeln('Skin sensitivity: ${user.skinSensitivity}');
    buffer.writeln('Body type / Hip fit: ${user.bodyType}');
    buffer.writeln('General movement routine: ${user.dailyRoutine}');
    buffer.writeln('Flow tendency: ${user.flowTendency}');
    buffer.writeln('Current phase: $phase');
    buffer.writeln('Cycle day: $cycleDay of ${user.cycleLength}');

    if (phase == 'Menstrual Phase') {
      buffer.writeln('She is currently on her period.');
    } else {
      buffer.writeln('Days until next period: $daysUntil');
    }

    if (entry != null) {
      buffer.writeln('Today\'s flow: ${entry.flow.label}');
      buffer.writeln('Today\'s activity / routine: ${entry.activityLevel}');
      if (entry.mood != null) {
        buffer.writeln('Today\'s mood: ${entry.mood!.label}');
      }
      if (entry.symptoms.isNotEmpty) {
        buffer.writeln('Today\'s symptoms: ${entry.symptoms.join(', ')}');
      }
      buffer.writeln(
          'Sleep last night: ${entry.sleepHours.toStringAsFixed(1)} hours');
      if (entry.notes.isNotEmpty) {
        buffer.writeln('Today\'s notes: ${entry.notes}');
      }
    }

    buffer.writeln(
      '\nUse this context to give personalised, relevant advice. '
      'Refer to her by name naturally. '
      'Always respond in English unless she writes in another language.',
    );

    return buffer.toString();
  }

  // ----------------------------------------------------------------
  // ONE-SHOT GENERATION (for journal / pad recommendations)
  // ----------------------------------------------------------------

  /// Generate a single text response. Returns the full text.
  Future<String> generate({
    required String prompt,
    required AppState state,
    String? customSystemPrompt,
    int maxTokens = 800,
  }) async {
    final apiKey = state.geminiApiKey;
    if (apiKey.isEmpty) {
      return 'Please add your free Gemini API key in Profile → AI Settings to enable AI responses.';
    }

    final url = Uri.parse('$_baseUrl:generateContent?key=$apiKey');
    final systemPrompt = customSystemPrompt ?? _buildSystemPrompt(state);

    final body = jsonEncode({
      'system_instruction': {
        'parts': [
          {'text': systemPrompt}
        ]
      },
      'contents': [
        {
          'role': 'user',
          'parts': [
            {'text': prompt}
          ]
        }
      ],
      'generationConfig': {
        'maxOutputTokens': maxTokens,
        'temperature': 0.7,
        'topP': 0.9,
      },
      'safetySettings': [
        {
          'category': 'HARM_CATEGORY_HARASSMENT',
          'threshold': 'BLOCK_ONLY_HIGH'
        },
        {
          'category': 'HARM_CATEGORY_HATE_SPEECH',
          'threshold': 'BLOCK_ONLY_HIGH'
        },
        {
          'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT',
          'threshold': 'BLOCK_ONLY_HIGH'
        },
        {
          'category': 'HARM_CATEGORY_DANGEROUS_CONTENT',
          'threshold': 'BLOCK_ONLY_HIGH'
        },
      ],
    });

    try {
      final response = await http
          .post(url,
              headers: {'Content-Type': 'application/json'}, body: body)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return _extractText(json);
      } else if (response.statusCode == 429) {
        return 'Cherry AI is busy right now. Please wait a moment and try again 💕';
      } else if (response.statusCode == 400) {
        final err = jsonDecode(response.body);
        debugPrint('Gemini 400: $err');
        if (response.body.contains('API_KEY_INVALID')) {
          return 'Your Gemini API key seems incorrect. Please check it in Profile → AI Settings.';
        }
        return 'Cherry AI encountered an issue. Please try again.';
      } else {
        debugPrint('Gemini error ${response.statusCode}: ${response.body}');
        return 'Cherry AI is taking a short break. Please try again in a moment 💕';
      }
    } on TimeoutException {
      return 'Cherry AI took too long to respond. Please check your internet and try again.';
    } catch (e) {
      debugPrint('GeminiService.generate error: $e');
      return 'Could not connect to Cherry AI. Please check your internet connection.';
    }
  }

  // ----------------------------------------------------------------
  // STREAMING CHAT (token-by-token, for chat screen)
  // ----------------------------------------------------------------

  /// Stream tokens for real-time chat responses.
  /// Yields text chunks as they arrive from the API.
  Stream<String> streamChat({
    required List<Map<String, dynamic>> history,
    required String userMessage,
    required AppState state,
  }) async* {
    final apiKey = state.geminiApiKey;
    if (apiKey.isEmpty) {
      yield 'Please add your free Gemini API key in Profile → AI Settings to enable AI responses. '
          'Get one free at aistudio.google.com/apikey 💕';
      return;
    }

    final url =
        Uri.parse('$_baseUrl:streamGenerateContent?alt=sse&key=$apiKey');
    final systemPrompt = _buildSystemPrompt(state);

    // Build conversation contents
    final contents = <Map<String, dynamic>>[];
    for (final msg in history) {
      contents.add({
        'role': msg['isUser'] == true ? 'user' : 'model',
        'parts': [
          {'text': msg['text'] as String}
        ]
      });
    }
    // Add current user message
    contents.add({
      'role': 'user',
      'parts': [
        {'text': userMessage}
      ]
    });

    final body = jsonEncode({
      'system_instruction': {
        'parts': [
          {'text': systemPrompt}
        ]
      },
      'contents': contents,
      'generationConfig': {
        'maxOutputTokens': 500,
        'temperature': 0.75,
        'topP': 0.9,
      },
      'safetySettings': [
        {
          'category': 'HARM_CATEGORY_HARASSMENT',
          'threshold': 'BLOCK_ONLY_HIGH'
        },
        {
          'category': 'HARM_CATEGORY_HATE_SPEECH',
          'threshold': 'BLOCK_ONLY_HIGH'
        },
        {
          'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT',
          'threshold': 'BLOCK_ONLY_HIGH'
        },
        {
          'category': 'HARM_CATEGORY_DANGEROUS_CONTENT',
          'threshold': 'BLOCK_ONLY_HIGH'
        },
      ],
    });

    try {
      final request = http.Request('POST', url)
        ..headers['Content-Type'] = 'application/json'
        ..body = body;

      final streamedResponse = await request
          .send()
          .timeout(const Duration(seconds: 60));

      if (streamedResponse.statusCode != 200) {
        yield 'Cherry AI is taking a short break. Please try again 💕';
        return;
      }

      final buffer = StringBuffer();

      await for (final chunk
          in streamedResponse.stream.transform(utf8.decoder)) {
        // SSE lines: each chunk may contain multiple "data: {...}" lines
        for (final line in chunk.split('\n')) {
          final trimmed = line.trim();
          if (!trimmed.startsWith('data:')) continue;

          final jsonStr = trimmed.substring(5).trim();
          if (jsonStr.isEmpty || jsonStr == '[DONE]') continue;

          try {
            final json = jsonDecode(jsonStr) as Map<String, dynamic>;
            final text = _extractText(json);
            if (text.isNotEmpty) {
              buffer.write(text);
              yield text;
            }
          } catch (_) {
            // Partial chunk — ignore and wait for more
          }
        }
      }

      if (buffer.isEmpty) {
        yield 'I did not quite catch that. Could you rephrase? 💕';
      }
    } on TimeoutException {
      yield 'Cherry AI took too long to respond. Please check your internet.';
    } catch (e) {
      debugPrint('GeminiService.streamChat error: $e');
      yield 'Could not connect to Cherry AI. Please check your internet connection.';
    }
  }

  // ----------------------------------------------------------------
  // JOURNAL GENERATION PROMPTS
  // ----------------------------------------------------------------

  /// Build a prompt for generating a personalised daily journal entry.
  static String buildJournalPrompt(AppState state) {
    final user = state.user;
    final phase = state.phase;
    final cycleDay = state.cycleDay;
    final entry = state.entryFor(DateTime.now());

    final buf = StringBuffer();
    buf.writeln(
      'Write a warm, personal, encouraging daily journal entry for ${user.name} '
      'based on her cycle data today. '
      'She is on cycle day $cycleDay, in her $phase. '
      'Keep it to 3 short paragraphs. '
      'Write in second person ("You..."). '
      'Do NOT use any markdown. '
      'End with one sentence of gentle encouragement.',
    );

    if (entry != null) {
      buf.writeln('Flow today: ${entry.flow.label}.');
      if (entry.mood != null) buf.writeln('Mood: ${entry.mood!.label}.');
      if (entry.symptoms.isNotEmpty) {
        buf.writeln('Symptoms logged: ${entry.symptoms.join(', ')}.');
      }
      buf.writeln('Sleep: ${entry.sleepHours.toStringAsFixed(1)} hours.');
      if (entry.notes.isNotEmpty) buf.writeln('Her note: "${entry.notes}".');
    }

    return buf.toString();
  }

  /// Build a prompt for the pad recommendation reason text.
  static String buildPadReasonPrompt({
    required String padType,
    required String phase,
    required String flowLevel,
    required List<String> symptoms,
    required String userName,
    String skinSensitivity = 'Normal',
    String dailyRoutine = 'Moderate',
    String bodyType = 'Regular',
  }) {
    return 'In 1–2 warm, reassuring sentences, explain to $userName why a "$padType" is '
        'the most comfortable and protective choice for her today. '
        'She is in her $phase with $flowLevel flow'
        '${symptoms.isNotEmpty ? ', logged symptoms: ${symptoms.join(', ')}' : ''}, '
        'skin type: $skinSensitivity, routine today: $dailyRoutine, and body fit: $bodyType. '
        'Highlight why it prevents rashes, chafing, and leaks. Friendly tone, no markdown.';
  }

  // ----------------------------------------------------------------
  // HELPERS
  // ----------------------------------------------------------------

  static String _extractText(Map<String, dynamic> json) {
    try {
      final candidates = json['candidates'] as List?;
      if (candidates == null || candidates.isEmpty) return '';
      final content = candidates[0]['content'] as Map<String, dynamic>?;
      if (content == null) return '';
      final parts = content['parts'] as List?;
      if (parts == null || parts.isEmpty) return '';
      return (parts[0]['text'] as String?) ?? '';
    } catch (_) {
      return '';
    }
  }
}
