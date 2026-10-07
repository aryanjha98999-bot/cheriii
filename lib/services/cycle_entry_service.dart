import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/cycle_entry.dart';
import '../models/symptom.dart';

class CycleEntryService {
  final SupabaseClient _supabase = Supabase.instance.client;

  User? get currentUser => _supabase.auth.currentUser;

  bool get isLoggedIn => currentUser != null;

  /// Fetch all cycle entries belonging to the logged-in user.
  Future<List<CycleEntry>> getEntries() async {
    final user = currentUser;

    if (user == null) {
      return [];
    }

    final response = await _supabase
        .from('cycle_entries')
        .select()
        .eq('user_id', user.id)
        .order('entry_date', ascending: true);

    return (response as List)
        .map(
          (json) => _fromSupabaseJson(
            Map<String, dynamic>.from(json),
          ),
        )
        .toList();
  }

  /// Fetch one entry for a particular date.
  Future<CycleEntry?> getEntry(DateTime date) async {
    final user = currentUser;

    if (user == null) {
      return null;
    }

    final dateKey = _dateKey(date);

    final response = await _supabase
        .from('cycle_entries')
        .select()
        .eq('user_id', user.id)
        .eq('entry_date', dateKey)
        .maybeSingle();

    if (response == null) {
      return null;
    }

    return _fromSupabaseJson(
      Map<String, dynamic>.from(response),
    );
  }

  /// Create or update a cycle entry.
  ///
  /// Because the database has:
  /// unique(user_id, entry_date)
  ///
  /// upsert() will update an existing entry for the same date
  /// instead of creating a duplicate.
  Future<void> saveEntry(CycleEntry entry) async {
    final user = currentUser;

    if (user == null) {
      throw Exception('No authenticated user found.');
    }

    final dateKey = _dateKey(entry.date);
    final data = <String, dynamic>{
      'user_id': user.id,
      'entry_date': dateKey,
      'flow': entry.flow.name,
      'mood': entry.mood?.name,
      'symptoms': entry.symptoms.toList(),
      'sleep_hours': entry.sleepHours,
      'notes': entry.notes,
      'updated_at': DateTime.now().toIso8601String(),
    };

    try {
      await _supabase.from('cycle_entries').upsert(
        data,
        onConflict: 'user_id,entry_date',
      );
    } catch (_) {
      // Fallback in case composite unique constraint isn't declared
      final existing = await _supabase
          .from('cycle_entries')
          .select('id')
          .eq('user_id', user.id)
          .eq('entry_date', dateKey)
          .maybeSingle();

      if (existing != null) {
        await _supabase
            .from('cycle_entries')
            .update(data)
            .eq('id', existing['id']);
      } else {
        await _supabase
            .from('cycle_entries')
            .insert(data);
      }
    }
  }

  /// Delete the cycle entry for a particular date.
  Future<void> deleteEntry(DateTime date) async {
    final user = currentUser;

    if (user == null) {
      throw Exception('No authenticated user found.');
    }

    await _supabase
        .from('cycle_entries')
        .delete()
        .eq('user_id', user.id)
        .eq('entry_date', _dateKey(date));
  }

  /// Convert Supabase data into our existing CycleEntry model.
  CycleEntry _fromSupabaseJson(Map<String, dynamic> json) {
    final moodName = json['mood'] as String?;

    return CycleEntry(
      date: DateTime.parse(json['entry_date'] as String),
      flow: FlowLevel.values.firstWhere(
        (flow) => flow.name == json['flow'],
        orElse: () => FlowLevel.none,
      ),
      mood: moodName == null
          ? null
          : Mood.values.firstWhere(
              (mood) => mood.name == moodName,
              orElse: () => Mood.okay,
            ),
      symptoms: ((json['symptoms'] as List?) ?? const [])
          .map((item) => item.toString())
          .toSet(),
      sleepHours: ((json['sleep_hours'] as num?) ?? 7).toDouble(),
      notes: (json['notes'] as String?) ?? '',
    );
  }

  /// Convert DateTime to Supabase DATE format.
  String _dateKey(DateTime date) {
    final localDate = DateTime(date.year, date.month, date.day);

    final year = localDate.year.toString().padLeft(4, '0');
    final month = localDate.month.toString().padLeft(2, '0');
    final day = localDate.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }
}