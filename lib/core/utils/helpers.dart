import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Helpers {
  Helpers._();

  /// Use the real device date instead of the old design/demo date.
  static const bool useDemoDate = false;

  // Kept only in case you want the demo mode again later.
  static final DateTime demoToday = DateTime(2024, 10, 8);
  static final DateTime demoSelected = DateTime(2024, 10, 15);

  /// Today's actual date.
  static DateTime get today => dateOnly(DateTime.now());

  /// Initial selected date on the calendar screen.
  static DateTime get initialCalendarDate => today;

  static DateTime dateOnly(DateTime d) =>
      DateTime(d.year, d.month, d.day);

  static DateTime addDays(DateTime d, int days) =>
      DateTime(d.year, d.month, d.day + days);

  static String dayKey(DateTime d) =>
      DateFormat('yyyy-MM-dd').format(d);

  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year &&
      a.month == b.month &&
      a.day == b.day;

  static int daysBetween(DateTime from, DateTime to) =>
      DateTime.utc(to.year, to.month, to.day)
          .difference(
            DateTime.utc(from.year, from.month, from.day),
          )
          .inDays;

  static String monthYear(DateTime d) =>
      DateFormat('MMMM yyyy').format(d);

  static String shortDate(DateTime d) =>
      DateFormat('MMM d, yyyy').format(d);

  static String longDate(DateTime d) =>
      DateFormat('EEE, MMM d, yyyy').format(d);

  static String time(DateTime d) =>
      DateFormat('h:mm a').format(d);

  static String timeOfDay(TimeOfDay t) =>
      DateFormat('h:mm a').format(
        DateTime(2000, 1, 1, t.hour, t.minute),
      );

  /// Sunday-first month grid; leading/trailing cells are null.
  static List<DateTime?> monthGrid(DateTime month) {
    final first = DateTime(month.year, month.month, 1);
    final lead = first.weekday % 7;
    final count =
        DateTime(month.year, month.month + 1, 0).day;

    final cells = <DateTime?>[
      for (var i = 0; i < lead; i++) null,
      for (var d = 1; d <= count; d++)
        DateTime(month.year, month.month, d),
    ];

    while (cells.length % 7 != 0) {
      cells.add(null);
    }

    return cells;
  }

  /// Layout scale relative to a 390dp wide design, clamped for safety.
  static double scale(BuildContext context) =>
      (MediaQuery.sizeOf(context).width / 390)
          .clamp(0.85, 1.25)
          .toDouble();

  static void showSnack(
    BuildContext context,
    String message,
  ) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message)),
      );
  }
}