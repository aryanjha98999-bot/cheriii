import 'package:supabase_flutter/supabase_flutter.dart';

class ActivityService {
  final SupabaseClient _supabase = Supabase.instance.client;

  User? get currentUser => _supabase.auth.currentUser;

  bool get isLoggedIn => currentUser != null;

  /// Log a meaningful user activity.
  ///
  /// Examples:
  /// - cycle_entry_saved
  /// - mood_logged
  /// - symptom_logged
  /// - sleep_logged
  /// - period_started
  /// - ai_question
  /// - journal_opened
  /// - wellness_tip_viewed
  /// - bookmark_added
  Future<void> logActivity(
    String eventType, {
    Map<String, dynamic> data = const {},
    DateTime? date,
  }) async {
    final user = currentUser;

    // Do nothing when the user isn't logged in.
    if (user == null) return;

    try {
      await _supabase.from('user_activity_events').insert({
        'user_id': user.id,
        'event_type': eventType,
        'event_date': _dateKey(date ?? DateTime.now()),
        'event_data': data,
      });
    } catch (e) {
      // Activity tracking should NEVER break the main app.
      //
      // If logging fails, the user's normal action should
      // still continue.
      //
      // We will add proper error reporting later.
      print('Activity logging failed: $e');
    }
  }

  /// Get activities for the current user.
  Future<List<Map<String, dynamic>>> getActivities({
    int limit = 100,
  }) async {
    final user = currentUser;

    if (user == null) return [];

    final response = await _supabase
        .from('user_activity_events')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false)
        .limit(limit);

    return (response as List)
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  /// Get activities for a particular day.
  Future<List<Map<String, dynamic>>> getActivitiesForDate(
    DateTime date,
  ) async {
    final user = currentUser;

    if (user == null) return [];

    final response = await _supabase
        .from('user_activity_events')
        .select()
        .eq('user_id', user.id)
        .eq('event_date', _dateKey(date))
        .order('created_at', ascending: true);

    return (response as List)
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  String _dateKey(DateTime date) {
    final localDate = DateTime(date.year, date.month, date.day);

    final year = localDate.year.toString().padLeft(4, '0');
    final month = localDate.month.toString().padLeft(2, '0');
    final day = localDate.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }
}