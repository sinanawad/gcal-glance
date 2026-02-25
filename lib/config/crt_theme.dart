import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Centralized CRT color palette and theme factory.
/// All color constants used across the retro UI redesign.
class CrtTheme {
  CrtTheme._();

  // Core palette
  static const Color background = Color(0xFF1a1a2e);
  static const Color timelineBg = Color(0xFF0d0d1a);
  static const Color clockFlap = Color(0xFF2d2d44);
  static const Color clockDigit = Color(0xFFe0e0e0);

  // Status colors
  static const Color ongoing = Color(0xFF4fc3f7);
  static const Color upcoming = Color(0xFFffb74d);
  static const Color normal = Color(0xFF66bb6a);

  // Text colors
  static const Color textPrimary = Color(0xFFe0e0e0);
  static const Color textSecondary = Color(0xFFb0b0b0);

  // Action colors
  static const Color joinActive = Color(0xFFef5350);
  static const Color joinDisabled = Color(0xFF757575);

  /// Converts a Google Calendar color (ARGB int) to a CRT-faded version.
  /// Blends toward textSecondary for a muted, CRT-appropriate tone.
  static Color fadedCalendarColor(int colorValue, {double alpha = 0.7}) {
    final original = Color(colorValue);
    // Desaturate by blending 60% original + 40% textSecondary grey.
    // Color.r/g/b return 0.0-1.0 doubles; scale back to 0-255 for fromRGBO.
    final r = ((original.r * 0.6 + textSecondary.r * 0.4) * 255).round();
    final g = ((original.g * 0.6 + textSecondary.g * 0.4) * 255).round();
    final b = ((original.b * 0.6 + textSecondary.b * 0.4) * 255).round();
    return Color.fromRGBO(r, g, b, alpha);
  }

  /// Returns a status color for the given [EventStatus] string.
  static Color statusColor(String status) {
    switch (status) {
      case 'ongoing':
        return ongoing;
      case 'upcoming':
        return upcoming;
      default:
        return normal;
    }
  }

  /// Material 3 dark ThemeData with CRT palette overrides.
  static ThemeData themeData() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        surface: background,
        primary: ongoing,
        secondary: upcoming,
        tertiary: normal,
        error: joinActive,
        onSurface: textPrimary,
        onPrimary: background,
        onSecondary: background,
      ),
      scaffoldBackgroundColor: background,
      snackBarTheme: SnackBarThemeData(
        backgroundColor: clockFlap,
        contentTextStyle: GoogleFonts.vt323(
          color: textPrimary,
          fontSize: 16,
        ),
        actionTextColor: upcoming,
        behavior: SnackBarBehavior.floating,
        width: 400,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: clockFlap,
          foregroundColor: textPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: textSecondary, width: 1),
          ),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: ongoing,
        linearTrackColor: clockFlap,
      ),
    );
  }
}
