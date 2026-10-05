import 'dart:convert';
import 'symptom.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/utils/helpers.dart';
import 'cycle_entry.dart';
import 'user_model.dart';

enum NotificationStyle { normal, discreet, silent }

class AppState extends ChangeNotifier {
  static const _kUser = 'cheri_user';
  static const _kEntries = 'cheri_entries';
  static const _kPeriod = 'cheri_period_days';
  static const _kSettings = 'cheri_settings';

  SharedPreferences? _prefs;

  // ---- Data ----
  UserModel user = UserModel.demo();
  final Map<String, CycleEntry> _entries = {};
  final Set<String> _periodDays = {};

  // ---- Navigation ----
  int tabIndex = 0;

  // ---- Settings ----
  bool onboardingDone = false;
  final Map<String, bool> reminders = {
    'period': true,
    'checkin': true,
    'water': true,
    'tips': true,
  };
  TimeOfDay remindTime = const TimeOfDay(hour: 9, minute: 0);
  NotificationStyle notificationStyle = NotificationStyle.normal;
  bool appLockEnabled = true;
  bool fingerprintEnabled = true;
  bool faceIdEnabled = false;
  bool pinEnabled = false;
  String pinCode = '';
  String language = 'English';
  final Set<String> bookmarks = {};

  // ---- Derived cycle info ----
  DateTime get nextPeriodDate => user.nextPeriodAfter(Helpers.today);
  int get daysUntilNextPeriod =>
      Helpers.daysBetween(Helpers.today, nextPeriodDate);
  int get cycleDay => user.cycleDayOn(Helpers.today);
  String get phase => user.phaseOn(Helpers.today);
  double get cycleProgress => cycleDay / user.cycleLength;

  // ---- Calendar queries ----
  bool isPeriodDay(DateTime d) => _periodDays.contains(Helpers.dayKey(d));
  bool isPredictedDay(DateTime d) =>
      !isPeriodDay(d) && user.isPredictedPeriod(d);
  bool isFertileDay(DateTime d) => user.isFertile(d);
  CycleEntry? entryFor(DateTime d) => _entries[Helpers.dayKey(d)];

  // ---- Mutations ----
  void setTab(int index) {
    if (index == tabIndex) return;
    tabIndex = index;
    notifyListeners();
  }

  void saveEntry(CycleEntry entry) {
    final date = Helpers.dateOnly(entry.date);
    final key = Helpers.dayKey(date);
    _entries[key] = entry;

    if (entry.isPeriodFlow) {
      final startsNewPeriod =
          !_periodDays.contains(Helpers.dayKey(Helpers.addDays(date, -1)));
      _periodDays.add(key);
      if (startsNewPeriod && date.isAfter(user.lastPeriodStart)) {
        user = user.copyWith(lastPeriodStart: date);
      }
    } else {
      _periodDays.remove(key);
    }
    _commit();
  }

  /// Quick "Log Period +" action: marks [date] as a medium-flow day.
  void logPeriod(DateTime date) {
    final existing = entryFor(date) ?? CycleEntry(date: Helpers.dateOnly(date));
    saveEntry(existing.copyWith(
      flow: existing.isPeriodFlow ? existing.flow : FlowLevel.medium,
    ));
  }

  void updateUser(UserModel updated) {
    user = updated;
    _commit();
  }

  void completeOnboarding() {
    onboardingDone = true;
    _commit();
  }

  void setReminder(String key, bool value) {
    reminders[key] = value;
    _commit();
  }

  void setRemindTime(TimeOfDay t) {
    remindTime = t;
    _commit();
  }

  void setNotificationStyle(NotificationStyle s) {
    notificationStyle = s;
    _commit();
  }

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

  void setLanguage(String v) {
    language = v;
    _commit();
  }

  bool isBookmarked(String id) => bookmarks.contains(id);

  void toggleBookmark(String id) {
    if (!bookmarks.remove(id)) bookmarks.add(id);
    _commit();
  }

  // ---- Persistence ----
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _prefs = prefs;

    final userJson = prefs.getString(_kUser);
    if (userJson != null) {
      user = UserModel.fromJson(jsonDecode(userJson) as Map<String, dynamic>);
    }

    final entriesJson = prefs.getString(_kEntries);
    if (entriesJson != null) {
      final map = jsonDecode(entriesJson) as Map<String, dynamic>;
      map.forEach((k, v) {
        _entries[k] = CycleEntry.fromJson(v as Map<String, dynamic>);
      });
    }

    final periodList = prefs.getStringList(_kPeriod);
    _periodDays.clear();
    if (periodList != null) {
      _periodDays.addAll(periodList);
    } else {
      _seedDemoPeriods();
    }

    final settingsJson = prefs.getString(_kSettings);
    if (settingsJson != null) {
      _applySettings(jsonDecode(settingsJson) as Map<String, dynamic>);
    }
  }

  void _seedDemoPeriods() {
    for (final start in [
      DateTime(2024, 7, 20),
      DateTime(2024, 8, 17),
      DateTime(2024, 9, 14),
    ]) {
      for (var i = 0; i < 5; i++) {
        _periodDays.add(Helpers.dayKey(Helpers.addDays(start, i)));
      }
    }
  }

  void _applySettings(Map<String, dynamic> s) {
    onboardingDone = (s['onboardingDone'] as bool?) ?? onboardingDone;
    final r = s['reminders'] as Map<String, dynamic>?;
    if (r != null) {
      r.forEach((k, v) => reminders[k] = v == true);
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
    bookmarks
      ..clear()
      ..addAll(((s['bookmarks'] as List?) ?? const []).map((e) => '$e'));
  }

  void _commit() {
    notifyListeners();
    _persist();
  }

  Future<void> _persist() async {
    final prefs = _prefs;
    if (prefs == null) return;
    await prefs.setString(_kUser, jsonEncode(user.toJson()));
    await prefs.setString(
      _kEntries,
      jsonEncode(_entries.map((k, v) => MapEntry(k, v.toJson()))),
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
      }),
    );
  }
}