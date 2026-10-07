import 'dart:convert';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/utils/helpers.dart';
import '../services/auth_service.dart';
import '../services/profile_service.dart';
import '../services/cycle_entry_service.dart';
import '../services/reminder_service.dart';
import '../services/learn_service.dart';
import 'cycle_entry.dart';
import 'symptom.dart';
import 'user_model.dart';

enum NotificationStyle {
  normal,
  discreet,
  silent,
}

class AppState extends ChangeNotifier {
  static const _kUser = 'cheri_user';
  static const _kEntries = 'cheri_entries';
  static const _kPeriod = 'cheri_period_days';
  static const _kSettings = 'cheri_settings';

  SharedPreferences? _prefs;

  final AuthService _authService = AuthService();
  final ProfileService _profileService = ProfileService();
  final CycleEntryService _cycleEntryService = CycleEntryService();
  final ReminderService _reminderService = ReminderService();
  final LearnService _learnService = LearnService();

  // ------------------------------------------------------------
  // DATA
  // ------------------------------------------------------------

  UserModel user = UserModel.defaultGuest();

  final Map<String, CycleEntry> _entries = {};
  final Set<String> _periodDays = {};

  Map<String, CycleEntry> get entries => Map.unmodifiable(_entries);

  List<CycleEntry> get allEntries {
    final list = _entries.values.toList();
    list.sort((a, b) => a.date.compareTo(b.date));
    return list;
  }

  Set<String> get periodDays => Set.unmodifiable(_periodDays);

  // ------------------------------------------------------------
  // AUTH / BACKEND STATE
  // ------------------------------------------------------------

  bool isProfileLoaded = false;
  bool isCycleDataLoaded = false;

  String? get currentUserId => _authService.currentUserId;
  String? get userEmail => _authService.currentUserEmail;
  bool get isLoggedIn => _authService.isLoggedIn;

  // ------------------------------------------------------------
  // NAVIGATION
  // ------------------------------------------------------------

  int tabIndex = 0;

  // ------------------------------------------------------------
  // SETTINGS
  // ------------------------------------------------------------

  bool onboardingDone = false;

  final Map<String, bool> reminders = {
    'period': true,
    'checkin': true,
    'water': true,
    'tips': true,
  };

  TimeOfDay remindTime = const TimeOfDay(hour: 9, minute: 0);

  NotificationStyle notificationStyle = NotificationStyle.normal;

  bool appLockEnabled = false;
  bool fingerprintEnabled = true;
  bool faceIdEnabled = false;
  bool pinEnabled = false;

  String pinCode = '';

  String language = 'English';

  String geminiApiKey = '';

  final Set<String> bookmarks = {};

  // ------------------------------------------------------------
  // DERIVED CYCLE INFO
  // ------------------------------------------------------------

  DateTime get nextPeriodDate => user.nextPeriodAfter(Helpers.today);

  int get daysUntilNextPeriod => user.daysUntilPeriodFrom(Helpers.today);

  int get cycleDay => user.cycleDayOn(Helpers.today);

  String get phase => user.phaseOn(Helpers.today);

  double get cycleProgress =>
      (cycleDay / user.cycleLength).clamp(0.0, 1.0);

  // ------------------------------------------------------------
  // CALENDAR QUERIES
  // ------------------------------------------------------------

  bool isPeriodDay(DateTime d) => _periodDays.contains(Helpers.dayKey(d));

  bool isPredictedDay(DateTime d) =>
      !isPeriodDay(d) && user.isPredictedPeriod(d);

  bool isFertileDay(DateTime d) => user.isFertile(d);

  CycleEntry? entryFor(DateTime d) => _entries[Helpers.dayKey(d)];

  // ------------------------------------------------------------
  // NAVIGATION
  // ------------------------------------------------------------

  void setTab(int index) {
    if (index == tabIndex) return;
    tabIndex = index;
    notifyListeners();
  }

  // ------------------------------------------------------------
  // CYCLE ENTRY
  // ------------------------------------------------------------

  void saveEntry(CycleEntry entry) {
    final date = Helpers.dateOnly(entry.date);
    final key = Helpers.dayKey(date);

    final oldLastPeriodStart = user.lastPeriodStart;

    final normalized = CycleEntry(
      date: date,
      flow: entry.flow,
      mood: entry.mood,
      symptoms: Set<String>.from(entry.symptoms),
      sleepHours: entry.sleepHours,
      notes: entry.notes,
      activityLevel: entry.activityLevel,
    );

    // Save locally
    _entries[key] = normalized;

    if (normalized.isPeriodFlow) {
      final startsNewPeriod =
          !_periodDays.contains(Helpers.dayKey(Helpers.addDays(date, -1)));

      _periodDays.add(key);

      if (startsNewPeriod && !date.isBefore(user.lastPeriodStart)) {
        user = user.copyWith(lastPeriodStart: date);
      }
    } else {
      _periodDays.remove(key);
    }

    _commit();

    // Sync to Supabase
    if (isLoggedIn) {
      unawaited(_saveEntryToSupabase(normalized, oldLastPeriodStart));
    }
  }

  Future<void> _saveEntryToSupabase(
    CycleEntry entry,
    DateTime oldLastPeriodStart,
  ) async {
    try {
      await _cycleEntryService.saveEntry(entry);

      if (entry.isPeriodFlow && entry.date.isAfter(oldLastPeriodStart)) {
        await _profileService.updateProfile(
          lastPeriodStart: entry.date,
        );
      }

      debugPrint('Cycle entry synced to Supabase: ${Helpers.dayKey(entry.date)}');
    } catch (e) {
      debugPrint('Failed to sync cycle entry to Supabase: $e');
    }
  }

  /// Quick "Log Period +" action.
  void logPeriod(DateTime date) {
    final existing = entryFor(date) ?? CycleEntry(date: Helpers.dateOnly(date));

    saveEntry(
      existing.copyWith(
        flow: existing.isPeriodFlow ? existing.flow : FlowLevel.medium,
      ),
    );
  }

  // ------------------------------------------------------------
  // USER / PROFILE
  // ------------------------------------------------------------

  void updateUser(UserModel updated, {bool syncRemote = true}) {
    user = updated;
    isProfileLoaded = true;
    _commit();

    if (syncRemote && isLoggedIn) {
      unawaited(_syncProfileToSupabase(updated));
    }
  }

  Future<void> _syncProfileToSupabase(UserModel updated) async {
    try {
      await _profileService.saveUserModel(updated, language: language);
      debugPrint('User profile synced to Supabase for ${updated.name}');
    } catch (e) {
      debugPrint('Failed to sync user profile to Supabase: $e');
    }
  }

  // ------------------------------------------------------------
  // SIGN OUT
  // ------------------------------------------------------------

  Future<void> signOut() async {
    try {
      await _authService.signOut();
    } catch (e) {
      debugPrint('Sign out error: $e');
    }

    // Reset user state to clean guest
    user = UserModel.defaultGuest();
    _entries.clear();
    _periodDays.clear();
    isProfileLoaded = false;
    isCycleDataLoaded = false;
    tabIndex = 0;

    final prefs = _prefs;
    if (prefs != null) {
      await prefs.remove(_kUser);
      await prefs.remove(_kEntries);
      await prefs.remove(_kPeriod);
    }

    notifyListeners();
  }

  // ------------------------------------------------------------
  // ONBOARDING
  // ------------------------------------------------------------

  void completeOnboarding() {
    onboardingDone = true;
    _commit();
  }

  // ------------------------------------------------------------
  // REMINDERS
  // ------------------------------------------------------------

  void setReminder(String key, bool value) {
    reminders[key] = value;
    _commit();
    if (isLoggedIn) {
      unawaited(syncRemindersToSupabase());
    }
  }

  void setRemindTime(TimeOfDay t) {
    remindTime = t;
    _commit();
    if (isLoggedIn) {
      unawaited(syncRemindersToSupabase());
    }
  }

  void setNotificationStyle(NotificationStyle s) {
    notificationStyle = s;
    _commit();
    if (isLoggedIn) {
      unawaited(syncRemindersToSupabase());
    }
  }

  Future<void> syncRemindersToSupabase() async {
    if (!isLoggedIn) return;
    try {
      await _reminderService.saveSettings(
        reminders: reminders,
        remindTime: remindTime,
        style: notificationStyle,
      );
    } catch (e) {
      debugPrint('Failed to sync reminders to Supabase: $e');
    }
  }

  Future<void> loadSupabaseReminders() async {
    if (!isLoggedIn) return;
    try {
      final s = await _reminderService.getSettings();
      if (s != null) {
        reminders['period'] = s['period_reminder'] == true;
        reminders['checkin'] = s['daily_checkin'] == true;
        reminders['water'] = s['water_reminder'] == true;
        reminders['tips'] = s['wellness_tips'] == true;

        final timeStr = s['remind_time'] as String?;
        if (timeStr != null && timeStr.isNotEmpty) {
          final parts = timeStr.split(':');
          if (parts.length >= 2) {
            final h = int.tryParse(parts[0]);
            final m = int.tryParse(parts[1]);
            if (h != null && m != null) {
              remindTime = TimeOfDay(hour: h, minute: m);
            }
          }
        }

        final styleStr = s['notification_style'] as String?;
        if (styleStr != null && styleStr.isNotEmpty) {
          notificationStyle = NotificationStyle.values.firstWhere(
            (e) => e.name == styleStr,
            orElse: () => NotificationStyle.normal,
          );
        }
      }
    } catch (e) {
      debugPrint('Failed to load Supabase reminders: $e');
    }
  }

  // ------------------------------------------------------------
  // APP LOCK
  // ------------------------------------------------------------

  void setAppLock(bool v) {
    appLockEnabled = v;
    _commit();
  }

  void setFingerprint(bool v) {
    fingerprintEnabled = v;
    _commit();
  }

  void setFaceId(bool v) {
    faceIdEnabled = v;
    _commit();
  }

  void setPin(String? pin) {
    pinEnabled = pin != null && pin.length == 4;
    pinCode = pinEnabled ? pin! : '';
    _commit();
  }

  // ------------------------------------------------------------
  // LANGUAGE
  // ------------------------------------------------------------

  void setLanguage(String v) {
    language = v;
    _commit();
    if (isLoggedIn) {
      unawaited(_profileService.updateProfile(language: v));
    }
  }

  void setGeminiApiKey(String key) {
    geminiApiKey = key.trim();
    _commit();
  }

  // ------------------------------------------------------------
  // BOOKMARKS
  // ------------------------------------------------------------

  bool isBookmarked(String id) => bookmarks.contains(id);

  void toggleBookmark(String id) {
    if (!bookmarks.remove(id)) {
      bookmarks.add(id);
    }
    _commit();
    if (isLoggedIn) {
      unawaited(_learnService.toggleBookmark(id));
    }
  }

  Future<void> loadSupabaseBookmarks() async {
    if (!isLoggedIn) return;
    try {
      final bms = await _learnService.getBookmarkedIds();
      bookmarks.addAll(bms);
    } catch (e) {
      debugPrint('Failed to load bookmarks: $e');
    }
  }

  // ------------------------------------------------------------
  // LOAD
  // ------------------------------------------------------------

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _prefs = prefs;

    // Load local user cache
    final userJson = prefs.getString(_kUser);
    if (userJson != null) {
      try {
        user = UserModel.fromJson(
          jsonDecode(userJson) as Map<String, dynamic>,
        );
      } catch (_) {
        user = UserModel.defaultGuest();
      }
    }

    // Load local entries
    final entriesJson = prefs.getString(_kEntries);
    if (entriesJson != null) {
      try {
        final map = jsonDecode(entriesJson) as Map<String, dynamic>;
        _entries.clear();
        map.forEach((key, value) {
          _entries[key] = CycleEntry.fromJson(value as Map<String, dynamic>);
        });
      } catch (_) {
        _entries.clear();
      }
    }

    // Load period days
    final periodList = prefs.getStringList(_kPeriod);
    _periodDays.clear();
    if (periodList != null) {
      _periodDays.addAll(periodList);
    }

    // Load settings
    final settingsJson = prefs.getString(_kSettings);
    if (settingsJson != null) {
      try {
        _applySettings(jsonDecode(settingsJson) as Map<String, dynamic>);
      } catch (_) {}
    }

    // If logged into Supabase, fetch real remote profile & entries
    if (isLoggedIn) {
      await loadSupabaseProfile();
      await loadSupabaseEntries();
      await loadSupabaseReminders();
      await loadSupabaseBookmarks();
    }

    notifyListeners();
  }

  // ------------------------------------------------------------
  // LOAD SUPABASE PROFILE
  // ------------------------------------------------------------

  Future<void> loadSupabaseProfile() async {
    if (!isLoggedIn) {
      isProfileLoaded = false;
      return;
    }

    try {
      final profile = await _profileService.getProfile();
      if (profile == null) {
        // No profile document in database yet
        isProfileLoaded = false;
        return;
      }

      final name = (profile['name'] as String?)?.trim();
      final age = profile['age'] as int?;
      final avatarAsset = profile['avatar_asset'] as String?;
      final cycleLength = profile['cycle_length'] as int?;
      final periodLength = profile['period_length'] as int?;
      final lastPeriodString = profile['last_period_start'] as String?;

      DateTime? lastPeriodStart;
      if (lastPeriodString != null && lastPeriodString.isNotEmpty) {
        lastPeriodStart = DateTime.tryParse(lastPeriodString);
      }

      final emailName = userEmail?.split('@').first ?? 'Friend';
      final resolvedName =
          (name != null && name.isNotEmpty) ? name : emailName;

      final skinSensitivity = profile['skin_sensitivity'] as String?;
      final bodyType = profile['body_type'] as String?;
      final dailyRoutine = profile['daily_routine'] as String?;
      final flowTendency = profile['flow_tendency'] as String?;

      user = UserModel(
        name: resolvedName,
        age: age ?? user.age,
        avatarAsset: (avatarAsset != null && avatarAsset.isNotEmpty)
            ? avatarAsset
            : user.avatarAsset,
        cycleLength: cycleLength ?? user.cycleLength,
        periodLength: periodLength ?? user.periodLength,
        lastPeriodStart: lastPeriodStart ?? user.lastPeriodStart,
        skinSensitivity: (skinSensitivity != null && skinSensitivity.isNotEmpty)
            ? skinSensitivity
            : user.skinSensitivity,
        bodyType: (bodyType != null && bodyType.isNotEmpty)
            ? bodyType
            : user.bodyType,
        dailyRoutine: (dailyRoutine != null && dailyRoutine.isNotEmpty)
            ? dailyRoutine
            : user.dailyRoutine,
        flowTendency: (flowTendency != null && flowTendency.isNotEmpty)
            ? flowTendency
            : user.flowTendency,
      );

      isProfileLoaded = true;

      final profileLanguage = profile['language'] as String?;
      if (profileLanguage != null && profileLanguage.isNotEmpty) {
        language = profileLanguage;
      }

      await _saveUserLocally();
    } catch (e) {
      debugPrint('Failed to load Supabase profile: $e');
    }
  }

  // ------------------------------------------------------------
  // LOAD SUPABASE CYCLE ENTRIES
  // ------------------------------------------------------------

  Future<void> loadSupabaseEntries() async {
    if (!isLoggedIn) {
      isCycleDataLoaded = false;
      return;
    }

    try {
      final entries = await _cycleEntryService.getEntries();

      _entries.clear();
      _periodDays.clear();

      for (final entry in entries) {
        final date = Helpers.dateOnly(entry.date);
        final key = Helpers.dayKey(date);

        _entries[key] = entry;

        if (entry.isPeriodFlow) {
          _periodDays.add(key);
        }
      }

      isCycleDataLoaded = true;
      await _persist();
      debugPrint('Loaded ${entries.length} cycle entries from Supabase.');
    } catch (e) {
      isCycleDataLoaded = false;
      debugPrint('Failed to load Supabase cycle entries: $e');
    }
  }

  // ------------------------------------------------------------
  // DELETE CYCLE ENTRY
  // ------------------------------------------------------------

  Future<void> deleteEntry(DateTime date) async {
    final normalizedDate = Helpers.dateOnly(date);
    final key = Helpers.dayKey(normalizedDate);

    _entries.remove(key);
    _periodDays.remove(key);
    _commit();

    if (!isLoggedIn) return;

    try {
      await _cycleEntryService.deleteEntry(normalizedDate);
      debugPrint('Cycle entry deleted from Supabase: $key');
    } catch (e) {
      debugPrint('Failed to delete cycle entry from Supabase: $e');
    }
  }

  // ------------------------------------------------------------
  // SETTINGS
  // ------------------------------------------------------------

  void _applySettings(Map<String, dynamic> s) {
    onboardingDone = (s['onboardingDone'] as bool?) ?? onboardingDone;

    final r = s['reminders'] as Map<String, dynamic>?;
    if (r != null) {
      r.forEach((key, value) {
        reminders[key] = value == true;
      });
    }

    remindTime = TimeOfDay(
      hour: (s['hour'] as int?) ?? remindTime.hour,
      minute: (s['minute'] as int?) ?? remindTime.minute,
    );

    notificationStyle = NotificationStyle.values.firstWhere(
      (e) => e.name == s['style'],
      orElse: () => NotificationStyle.normal,
    );

    appLockEnabled = (s['appLock'] as bool?) ?? appLockEnabled;
    fingerprintEnabled = (s['fingerprint'] as bool?) ?? fingerprintEnabled;
    faceIdEnabled = (s['faceId'] as bool?) ?? faceIdEnabled;
    pinEnabled = (s['pinEnabled'] as bool?) ?? pinEnabled;
    pinCode = (s['pin'] as String?) ?? pinCode;
    language = (s['language'] as String?) ?? language;
    geminiApiKey = (s['geminiApiKey'] as String?) ?? geminiApiKey;

    bookmarks
      ..clear()
      ..addAll(((s['bookmarks'] as List?) ?? const []).map((e) => '$e'));
  }

  // ------------------------------------------------------------
  // PERSISTENCE
  // ------------------------------------------------------------

  Future<void> _saveUserLocally() async {
    final prefs = _prefs;
    if (prefs == null) return;
    await prefs.setString(_kUser, jsonEncode(user.toJson()));
  }

  void _commit() {
    notifyListeners();
    unawaited(_persist());
  }

  Future<void> _persist() async {
    final prefs = _prefs;
    if (prefs == null) return;

    await prefs.setString(_kUser, jsonEncode(user.toJson()));
    await prefs.setString(
      _kEntries,
      jsonEncode(
        _entries.map((key, value) => MapEntry(key, value.toJson())),
      ),
    );
    await prefs.setStringList(_kPeriod, _periodDays.toList());
    await prefs.setString(
      _kSettings,
      jsonEncode({
        'onboardingDone': onboardingDone,
        'reminders': reminders,
        'hour': remindTime.hour,
        'minute': remindTime.minute,
        'style': notificationStyle.name,
        'appLock': appLockEnabled,
        'fingerprint': fingerprintEnabled,
        'faceId': faceIdEnabled,
        'pinEnabled': pinEnabled,
        'pin': pinCode,
        'language': language,
        'bookmarks': bookmarks.toList(),
        'geminiApiKey': geminiApiKey,
      }),
    );
  }
}