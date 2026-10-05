import 'package:flutter/material.dart';

class Symptom {
  const Symptom(this.id, this.label, this.icon);

  final String id;
  final String label;
  final IconData icon;

  static const Symptom cramps =
      Symptom('cramps', 'Cramps', Icons.flash_on_rounded);
  static const Symptom mood =
      Symptom('mood', 'Mood', Icons.sentiment_satisfied_alt_outlined);
  static const Symptom headache =
      Symptom('headache', 'Headache', Icons.sick_outlined);
  static const Symptom acne = Symptom('acne', 'Acne', Icons.blur_on_rounded);
  static const Symptom bloating =
      Symptom('bloating', 'Bloating', Icons.bubble_chart_outlined);
  static const Symptom fatigue =
      Symptom('fatigue', 'Fatigue', Icons.bedtime_outlined);

  static const List<Symptom> calendarSet = [
    cramps,
    mood,
    headache,
    acne,
    bloating,
  ];

  static const List<Symptom> checkInSet = [
    cramps,
    bloating,
    headache,
    acne,
    fatigue,
  ];

  static const List<Symptom> all = [
    cramps,
    mood,
    headache,
    acne,
    bloating,
    fatigue,
  ];

  static Symptom byId(String id) =>
      all.firstWhere((s) => s.id == id, orElse: () => cramps);
}

enum FlowLevel {
  none('None', Icons.block_rounded, Color(0xFFF3E6E8)),
  light('Light', Icons.water_drop_outlined, Color(0xFFFFE3E8)),
  medium('Medium', Icons.water_drop_rounded, Color(0xFFFFD0D8)),
  heavy('Heavy', Icons.water_drop_rounded, Color(0xFFFFB9C6)),
  spotting('Spotting', Icons.grain_rounded, Color(0xFFFFE3E8));

  const FlowLevel(this.label, this.icon, this.tint);

  final String label;
  final IconData icon;
  final Color tint;
}

enum Mood {
  happy('Happy', '😊', Color(0xFFFFE08A)),
  calm('Calm', '😌', Color(0xFFF9B3B8)),
  okay('Okay', '😐', Color(0xFFFFE7A0)),
  sad('Sad', '😢', Color(0xFFBFDDF5)),
  anxious('Anxious', '😟', Color(0xFFF8C0C0));

  const Mood(this.label, this.emoji, this.tint);

  final String label;
  final String emoji;
  final Color tint;
}