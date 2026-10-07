import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../widgets/ai_message_card.dart';

class AiChatService {
  final SupabaseClient _supabase = Supabase.instance.client;

  User? get currentUser => _supabase.auth.currentUser;

  Future<List<ChatMessage>> loadHistory() async {
    final user = currentUser;
    if (user == null) return [];

    try {
      final response = await _supabase
          .from('ai_conversations')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: true);

      return (response as List).map((row) {
        final role = row['role'] as String?;
        final message = (row['message'] as String?) ?? '';
        final createdAtStr = row['created_at'] as String?;
        final time = createdAtStr != null
            ? DateTime.tryParse(createdAtStr) ?? DateTime.now()
            : DateTime.now();

        return ChatMessage(
          text: message,
          isUser: role == 'user',
          time: time,
        );
      }).toList();
    } catch (e) {
      debugPrint('AiChatService.loadHistory error: $e');
      return [];
    }
  }

  Future<void> saveMessage({
    required bool isUser,
    required String message,
  }) async {
    final user = currentUser;
    if (user == null) return;

    try {
      await _supabase.from('ai_conversations').insert({
        'user_id': user.id,
        'role': isUser ? 'user' : 'assistant',
        'message': message,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('AiChatService.saveMessage error: $e');
    }
  }

  Future<void> clearHistory() async {
    final user = currentUser;
    if (user == null) return;

    try {
      await _supabase
          .from('ai_conversations')
          .delete()
          .eq('user_id', user.id);
    } catch (e) {
      debugPrint('AiChatService.clearHistory error: $e');
    }
  }
}
