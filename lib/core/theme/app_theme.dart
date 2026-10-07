import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/colors.dart';

class AppTextStyles {
  AppTextStyles._();

  static TextStyle _poppins(
    double size,
    FontWeight weight,
    Color color, {
    double? height,
    double? letterSpacing,
  }) =>
      GoogleFonts.poppins(
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height,
        letterSpacing: letterSpacing,
      );

  static TextStyle get screenTitle =>
      _poppins(18, FontWeight.w600, AppColors.textPrimary);
  static TextStyle get headline =>
      _poppins(24, FontWeight.w600, AppColors.textPrimary, height: 1.25);
  static TextStyle get sectionTitle =>
      _poppins(16, FontWeight.w600, AppColors.textPrimary);
  static TextStyle get cardTitle =>
      _poppins(14, FontWeight.w600, AppColors.textPrimary);
  static TextStyle get body =>
      _poppins(13, FontWeight.w400, AppColors.textPrimary, height: 1.45);
  static TextStyle get bodyMuted =>
      _poppins(12.5, FontWeight.w400, AppColors.textSecondary, height: 1.4);
  static TextStyle get caption =>
      _poppins(11, FontWeight.w400, AppColors.textSecondary);
  static TextStyle get label =>
      _poppins(12, FontWeight.w500, AppColors.textPrimary);
  static TextStyle get link =>
      _poppins(12, FontWeight.w600, AppColors.crimson);
  static TextStyle get button =>
      _poppins(16, FontWeight.w600, Colors.white, letterSpacing: 0.2);
  static TextStyle get bigNumber =>
      _poppins(40, FontWeight.w700, AppColors.textPrimary, height: 1.1);

  /// Script logo font for the splash "Cheri" wordmark.
  static TextStyle get script => GoogleFonts.greatVibes(
        fontSize: 78,
        color: AppColors.crimson,
        height: 1.0,
      );
}

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.crimson,
      brightness: Brightness.light,
    ).copyWith(
      primary: AppColors.crimson,
      onPrimary: Colors.white,
      secondary: AppColors.rose,
      onSecondary: Colors.white,
      surface: Colors.white,
      onSurface: AppColors.textPrimary,
      surfaceTint: Colors.transparent,
      error: AppColors.crimsonDark,
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      brightness: Brightness.light,
    );
final textTheme = base.textTheme.apply(
  fontFamily: GoogleFonts.poppins().fontFamily,
  bodyColor: AppColors.textPrimary,
  displayColor: AppColors.textPrimary,
);

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.bgTop,
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      splashFactory: InkRipple.splashFactory,
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: AppTextStyles.screenTitle,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.crimson,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: const StadiumBorder(),
          textStyle: AppTextStyles.button,
          elevation: 0,
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: const WidgetStatePropertyAll(Colors.white),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.crimson
              : AppColors.toggleOff,
        ),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      sliderTheme: SliderThemeData(
        trackHeight: 3,
        activeTrackColor: AppColors.crimson,
        inactiveTrackColor: AppColors.roseLight.withValues(alpha: 0.45),
        thumbColor: AppColors.crimson,
        overlayColor: AppColors.crimson.withValues(alpha: 0.12),
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
        tickMarkShape: SliderTickMarkShape.noTickMark,
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.crimson
              : AppColors.textSecondary,
        ),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: AppColors.crimson,
        selectionColor: AppColors.roseLight.withValues(alpha: 0.5),
        selectionHandleColor: AppColors.crimson,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.85),
        hintStyle: AppTextStyles.bodyMuted,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.crimson, width: 1.2),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.textPrimary,
        contentTextStyle: AppTextStyles.body.copyWith(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }
}