import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LearnService {
  final SupabaseClient _supabase = Supabase.instance.client;

  User? get currentUser => _supabase.auth.currentUser;

  Future<List<Map<String, dynamic>>> getLearningContent() async {
    try {
      final response = await _supabase
          .from('learning_content')
          .select()
          .order('created_at', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('LearnService.getLearningContent error: $e');
      return [];
    }
  }

  Future<Set<String>> getBookmarkedIds() async {
    final user = currentUser;
    if (user == null) return {};

    try {
      final response = await _supabase
          .from('bookmarks')
          .select('content_id')
          .eq('user_id', user.id);

      final set = <String>{};
      for (final row in response) {
        final cid = row['content_id']?.toString();
        if (cid != null && cid.isNotEmpty) {
          set.add(cid);
        }
      }
      return set;
    } catch (e) {
      debugPrint('LearnService.getBookmarkedIds error: $e');
      return {};
    }
  }

  Future<void> toggleBookmark(String contentId) async {
    final user = currentUser;
    if (user == null) return;

    try {
      final existing = await _supabase
          .from('bookmarks')
          .select('id')
          .eq('user_id', user.id)
          .eq('content_id', contentId)
          .maybeSingle();

      if (existing != null) {
        await _supabase
            .from('bookmarks')
            .delete()
            .eq('id', existing['id']);
      } else {
        await _supabase.from('bookmarks').insert({
          'user_id': user.id,
          'content_id': contentId,
          'created_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      debugPrint('LearnService.toggleBookmark error: $e');
    }
  }
}
