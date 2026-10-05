import '../core/utils/helpers.dart';
import 'symptom.dart';

class CycleEntry {
  const CycleEntry({
    required this.date,
    this.flow = FlowLevel.none,
    this.mood,
    this.symptoms = const <String>{},
    this.sleepHours = 7,
    this.notes = '',
  });

  final DateTime date;
  final FlowLevel flow;
  final Mood? mood;
  final Set<String> symptoms;
  final double sleepHours;
  final String notes;

  bool get isPeriodFlow =>
      flow == FlowLevel.light ||
      flow == FlowLevel.medium ||
      flow == FlowLevel.heavy;

  CycleEntry copyWith({
    FlowLevel? flow,
    Mood? mood,
    bool clearMood = false,
    Set<String>? symptoms,
    double? sleepHours,
    String? notes,
  }) {
    return CycleEntry(
      date: date,
      flow: flow ?? this.flow,
      mood: clearMood ? null : (mood ?? this.mood),
      symptoms: symptoms ?? this.symptoms,
      sleepHours: sleepHours ?? this.sleepHours,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() => {
        'date': Helpers.dayKey(date),
        'flow': flow.name,
        'mood': mood?.name,
        'symptoms': symptoms.toList(),
        'sleep': sleepHours,
        'notes': notes,
      };

  factory CycleEntry.fromJson(Map<String, dynamic> json) {
    final moodName = json['mood'] as String?;
    return CycleEntry(
      date: DateTime.parse(json['date'] as String),
      flow: FlowLevel.values.firstWhere(
        (f) => f.name == json['flow'],
        orElse: () => FlowLevel.none,
      ),
      mood: moodName == null
          ? null
          : Mood.values.firstWhere(
              (m) => m.name == moodName,
              orElse: () => Mood.okay,
            ),
      symptoms: ((json['symptoms'] as List?) ?? const [])
          .map((e) => e.toString())
          .toSet(),
      sleepHours: ((json['sleep'] as num?) ?? 7).toDouble(),
      notes: (json['notes'] as String?) ?? '',
    );
  }
}