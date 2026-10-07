import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/app_state.dart';

class ReminderService {
  final SupabaseClient _supabase = Supabase.instance.client;

  User? get currentUser => _supabase.auth.currentUser;

  Future<Map<String, dynamic>?> getSettings() async {
    final user = currentUser;
    if (user == null) return null;

    try {
      return await _supabase
          .from('reminder_settings')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();
    } catch (e) {
      debugPrint('ReminderService.getSettings error: $e');
      return null;
    }
  }

  Future<void> saveSettings({
    required Map<String, bool> reminders,
    required TimeOfDay remindTime,
    required NotificationStyle style,
  }) async {
    final user = currentUser;
    if (user == null) return;

    final hourStr = remindTime.hour.toString().padLeft(2, '0');
    final minStr = remindTime.minute.toString().padLeft(2, '0');
    final timeString = '$hourStr:$minStr:00';

    final data = <String, dynamic>{
      'user_id': user.id,
      'period_reminder': reminders['period'] ?? true,
      'daily_checkin': reminders['checkin'] ?? true,
      'water_reminder': reminders['water'] ?? true,
      'wellness_tips': reminders['tips'] ?? true,
      'remind_time': timeString,
      'notification_style': style.name,
      'updated_at': DateTime.now().toIso8601String(),
    };

    try {
      final existing = await _supabase
          .from('reminder_settings')
          .select('id')
          .eq('user_id', user.id)
          .maybeSingle();

      if (existing != null) {
        await _supabase
            .from('reminder_settings')
            .update(data)
            .eq('id', existing['id']);
      } else {
        await _supabase.from('reminder_settings').insert(data);
      }
      debugPrint('Reminder settings saved to Supabase');
    } catch (e) {
      debugPrint('ReminderService.saveSettings error: $e');
    }
  }
}
