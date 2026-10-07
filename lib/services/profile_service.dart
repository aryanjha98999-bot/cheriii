import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user_model.dart';

class ProfileService {
  final SupabaseClient _supabase = Supabase.instance.client;

  User? get currentUser => _supabase.auth.currentUser;

  Future<Map<String, dynamic>?> getProfile() async {
    final user = currentUser;
    if (user == null) return null;

    try {
      return await _supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();
    } catch (e) {
      debugPrint('ProfileService.getProfile error: $e');
      return null;
    }
  }

  Future<void> createProfile({
    required String name,
    int? age,
    int cycleLength = 28,
    int periodLength = 5,
    DateTime? lastPeriodStart,
    String language = 'English',
    String? avatarAsset,
  }) async {
    final user = currentUser;
    if (user == null) {
      throw Exception('No authenticated user found.');
    }

    final data = <String, dynamic>{
      'id': user.id,
      'name': name.trim(),
      'age': age,
      'cycle_length': cycleLength,
      'period_length': periodLength,
      'last_period_start':
          lastPeriodStart?.toIso8601String().split('T').first,
      'language': language,
      'avatar_asset': avatarAsset,
      'updated_at': DateTime.now().toIso8601String(),
    };

    await _supabase.from('profiles').upsert(data);
  }

  Future<void> updateProfile({
    String? name,
    int? age,
    int? cycleLength,
    int? periodLength,
    DateTime? lastPeriodStart,
    String? language,
    String? avatarAsset,
  }) async {
    final user = currentUser;
    if (user == null) {
      throw Exception('No authenticated user found.');
    }

    final data = <String, dynamic>{
      'id': user.id,
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (name != null) data['name'] = name.trim();
    if (age != null) data['age'] = age;
    if (cycleLength != null) data['cycle_length'] = cycleLength;
    if (periodLength != null) data['period_length'] = periodLength;
    if (lastPeriodStart != null) {
      data['last_period_start'] =
          lastPeriodStart.toIso8601String().split('T').first;
    }
    if (language != null) data['language'] = language;
    if (avatarAsset != null) data['avatar_asset'] = avatarAsset;

    await _supabase.from('profiles').upsert(data);
  }

  Future<void> saveUserModel(UserModel userModel, {String? language}) async {
    await updateProfile(
      name: userModel.name,
      age: userModel.age,
      cycleLength: userModel.cycleLength,
      periodLength: userModel.periodLength,
      lastPeriodStart: userModel.lastPeriodStart,
      avatarAsset: userModel.avatarAsset,
      language: language,
    );
  }
}