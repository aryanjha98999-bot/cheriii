import '../core/constants/strings.dart';
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

  factory UserModel.demo() => UserModel(
        name: 'Aarohi',
        age: 19,
        avatarAsset: AppAssets.avatar,
        cycleLength: 28,
        periodLength: 5,
        lastPeriodStart: DateTime(2024, 9, 14),
      );

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
  int cycleDayOn(DateTime date) =>
      Helpers.daysBetween(lastPeriodStart, date) % cycleLength + 1;

  /// Start date of the next period strictly after [date].
  DateTime nextPeriodAfter(DateTime date) {
    final diff = Helpers.daysBetween(lastPeriodStart, date);
    final n = (diff / cycleLength).floor() + 1;
    return Helpers.addDays(lastPeriodStart, n * cycleLength);
  }

  int get ovulationDay => cycleLength - 14;

  bool isPredictedPeriod(DateTime date) {
    final diff = Helpers.daysBetween(lastPeriodStart, date);
    return diff >= cycleLength && cycleDayOn(date) <= periodLength;
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
    final fallback = UserModel.demo();
    return UserModel(
      name: (json['name'] as String?) ?? fallback.name,
      age: (json['age'] as int?) ?? fallback.age,
      avatarAsset: (json['avatar'] as String?) ?? fallback.avatarAsset,
      cycleLength: (json['cycleLength'] as int?) ?? fallback.cycleLength,
      periodLength: (json['periodLength'] as int?) ?? fallback.periodLength,
      lastPeriodStart: json['lastPeriodStart'] == null
          ? fallback.lastPeriodStart
          : DateTime.parse(json['lastPeriodStart'] as String),
    );
  }
}