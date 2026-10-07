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
    String skinSensitivity = 'Normal',
    String bodyType = 'Regular fit',
    String dailyRoutine = 'Moderate / Mixed',
    String flowTendency = 'Medium balanced',
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
      'skin_sensitivity': skinSensitivity,
      'body_type': bodyType,
      'daily_routine': dailyRoutine,
      'flow_tendency': flowTendency,
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
    String? skinSensitivity,
    String? bodyType,
    String? dailyRoutine,
    String? flowTendency,
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
    if (skinSensitivity != null) data['skin_sensitivity'] = skinSensitivity;
    if (bodyType != null) data['body_type'] = bodyType;
    if (dailyRoutine != null) data['daily_routine'] = dailyRoutine;
    if (flowTendency != null) data['flow_tendency'] = flowTendency;

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
      skinSensitivity: userModel.skinSensitivity,
      bodyType: userModel.bodyType,
      dailyRoutine: userModel.dailyRoutine,
      flowTendency: userModel.flowTendency,
      language: language,
    );
  }
}