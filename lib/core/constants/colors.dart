import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Brand
  static const Color crimson = Color(0xFFA8102E);
  static const Color crimsonDark = Color(0xFF8E0C25);
  static const Color rose = Color(0xFFC8183F);
  static const Color roseLight = Color(0xFFF4A6B5);
  static const Color roseTint = Color(0xFFFFE3E8);

  // Backgrounds
  static const Color bgTop = Color(0xFFFFF4F4);
  static const Color bgBottom = Color(0xFFFFE3E6);
  static const Color card = Color(0xD9FFFFFF); // white @ 85%

  // Text
  static const Color textPrimary = Color(0xFF4A1420);
  static const Color textSecondary = Color(0xFF8C6A70);
  static const Color navInactive = Color(0xFF9A9094);

  // Calendar
  static const Color fertile = Color(0xFFCFE8F6);
  static const Color fertileText = Color(0xFF2F7FB0);
  static const Color predicted = Color(0xFFF08A73);
  static const Color predictedFill = Color(0xFFFFD6CC);
  static const Color todayRing = Color(0xFF4A1420);

  // Misc
  static const Color divider = Color(0xFFF5D9DD);
  static const Color toggleOff = Color(0xFFD9D6D8);

  // Tints for icon circles
  static const Color tintYellow = Color(0xFFFFE9A8);
  static const Color tintBlue = Color(0xFFD6EAF8);
  static const Color tintPink = Color(0xFFFFD6DD);
  static const Color tintOrange = Color(0xFFFFE0C2);
  static const Color tintGreen = Color(0xFFDDF0DD);

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [bgTop, bgBottom],
  );

  static const LinearGradient buttonGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [crimson, crimsonDark],
  );

  static const List<BoxShadow> softShadow = [
    BoxShadow(
      color: Color(0x1FC8183F),
      blurRadius: 16,
      offset: Offset(0, 4),
    ),
  ];
}
