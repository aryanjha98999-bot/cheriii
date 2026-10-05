import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Helpers {
  Helpers._();

  /// When true, "today" is pinned to Oct 8, 2024 so the UI matches the
  /// design showcase. Set to false to use the real device date.
  static const bool useDemoDate = true;
  static final DateTime demoToday = DateTime(2024, 10, 8);
  static final DateTime demoSelected = DateTime(2024, 10, 15);

  static DateTime get today =>
      useDemoDate ? demoToday : dateOnly(DateTime.now());

  /// Initial selected date on the calendar screen.
  static DateTime get initialCalendarDate =>
      useDemoDate ? demoSelected : today;

  static DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  static DateTime addDays(DateTime d, int days) =>
      DateTime(d.year, d.month, d.day + days);

  static String dayKey(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static int daysBetween(DateTime from, DateTime to) =>
      DateTime.utc(to.year, to.month, to.day)
          .difference(DateTime.utc(from.year, from.month, from.day))
          .inDays;

  static String monthYear(DateTime d) => DateFormat('MMMM yyyy').format(d);
  static String shortDate(DateTime d) => DateFormat('MMM d, yyyy').format(d);
  static String longDate(DateTime d) => DateFormat('EEE, MMM d, yyyy').format(d);
  static String time(DateTime d) => DateFormat('h:mm a').format(d);

  static String timeOfDay(TimeOfDay t) =>
      DateFormat('h:mm a').format(DateTime(2000, 1, 1, t.hour, t.minute));

  /// Sunday-first month grid; leading/trailing cells are null.
  static List<DateTime?> monthGrid(DateTime month) {
    final first = DateTime(month.year, month.month, 1);
    final lead = first.weekday % 7; // Sunday == 0
    final count = DateTime(month.year, month.month + 1, 0).day;
    final cells = <DateTime?>[
      for (var i = 0; i < lead; i++) null,
      for (var d = 1; d <= count; d++) DateTime(month.year, month.month, d),
    ];
    while (cells.length % 7 != 0) {
      cells.add(null);
    }
    return cells;
  }

  /// Layout scale relative to a 390dp wide design, clamped for safety.
  static double scale(BuildContext context) =>
      (MediaQuery.sizeOf(context).width / 390).clamp(0.85, 1.25).toDouble();

  static void showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}