import '../core/utils/helpers.dart';

class UserModel {
  const UserModel({
    required this.name,
    required this.age,
    required this.avatarAsset,
    required this.cycleLength,
    required this.periodLength,
    required this.lastPeriodStart,
  });

  final String name;
  final int age;
  final String avatarAsset;
  final int cycleLength;
  final int periodLength;
  final DateTime lastPeriodStart;

  factory UserModel.demo() {
    final now = Helpers.today;
    return UserModel(
      name: 'Aarohi',
      age: 21,
      avatarAsset: 'flower',
      cycleLength: 28,
      periodLength: 5,
      lastPeriodStart: Helpers.addDays(now, -14),
    );
  }

  factory UserModel.defaultGuest() {
    final now = Helpers.today;
    return UserModel(
      name: 'Friend',
      age: 22,
      avatarAsset: 'flower',
      cycleLength: 28,
      periodLength: 5,
      lastPeriodStart: Helpers.addDays(now, -14),
    );
  }

  UserModel copyWith({
    String? name,
    int? age,
    String? avatarAsset,
    int? cycleLength,
    int? periodLength,
    DateTime? lastPeriodStart,
  }) {
    return UserModel(
      name: name ?? this.name,
      age: age ?? this.age,
      avatarAsset: avatarAsset ?? this.avatarAsset,
      cycleLength: cycleLength ?? this.cycleLength,
      periodLength: periodLength ?? this.periodLength,
      lastPeriodStart: lastPeriodStart ?? this.lastPeriodStart,
    );
  }

  /// Day number within the cycle (1-based) on [date].
  int cycleDayOn(DateTime date) {
    final diff = Helpers.daysBetween(lastPeriodStart, date);
    if (diff < 0) return 1;
    return (diff % cycleLength) + 1;
  }

  /// Start date of the upcoming period on or after [date].
  DateTime nextPeriodAfter(DateTime date) {
    final diff = Helpers.daysBetween(lastPeriodStart, date);
    if (diff < 0) {
      return lastPeriodStart;
    }
    final remainder = diff % cycleLength;
    if (remainder == 0 && diff > 0) {
      // Period is expected today
      return Helpers.dateOnly(date);
    }
    final daysUntil = cycleLength - remainder;
    return Helpers.addDays(date, daysUntil);
  }

  /// Number of days from [date] until the next predicted period start.
  int daysUntilPeriodFrom(DateTime date) {
    final diff = Helpers.daysBetween(lastPeriodStart, date);
    if (diff < 0) return 0;
    final remainder = diff % cycleLength;
    if (remainder == 0 && diff > 0) return 0; // Starts today
    return cycleLength - remainder;
  }

  int get ovulationDay => (cycleLength - 14).clamp(10, cycleLength - 5);

  bool isPredictedPeriod(DateTime date) {
    final diff = Helpers.daysBetween(lastPeriodStart, date);
    if (diff < 0) return false;
    final d = cycleDayOn(date);
    return d <= periodLength;
  }

  bool isFertile(DateTime date) {
    if (Helpers.daysBetween(lastPeriodStart, date) < 0) return false;
    final d = cycleDayOn(date);
    return d >= ovulationDay - 5 && d <= ovulationDay + 1;
  }

  String phaseOn(DateTime date) {
    final d = cycleDayOn(date);
    if (d <= periodLength) return 'Menstrual Phase';
    if (d < ovulationDay - 1) return 'Follicular Phase';
    if (d <= ovulationDay + 1) return 'Ovulation Phase';
    return 'Luteal Phase';
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'age': age,
        'avatar': avatarAsset,
        'cycleLength': cycleLength,
        'periodLength': periodLength,
        'lastPeriodStart': Helpers.dayKey(lastPeriodStart),
      };

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final fallback = UserModel.defaultGuest();
    final dateStr = json['lastPeriodStart'] as String?;
    DateTime parsedDate;
    if (dateStr != null && dateStr.isNotEmpty) {
      parsedDate = DateTime.tryParse(dateStr) ?? fallback.lastPeriodStart;
    } else {
      parsedDate = fallback.lastPeriodStart;
    }

    return UserModel(
      name: (json['name'] as String?)?.trim().isNotEmpty == true
          ? json['name'] as String
          : fallback.name,
      age: (json['age'] as int?) ?? fallback.age,
      avatarAsset: (json['avatar'] as String?) ?? fallback.avatarAsset,
      cycleLength: (json['cycleLength'] as int?) ?? fallback.cycleLength,
      periodLength: (json['periodLength'] as int?) ?? fallback.periodLength,
      lastPeriodStart: parsedDate,
    );
  }
}