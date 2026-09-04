import 'package:flutter/material.dart';

class PrimeTheme {
  PrimeTheme._();

  // ── Background ──
  static const Color bgDeep = Color(0xFF030810);
  static const Color bgSurface = Color(0xFF0a0f1a);
  static const Color bgCard = Color(0xFF0d1424);
  static const Color bgElevated = Color(0xFF111b30);

  // ── Intelligence (Cyan) ──
  static const Color primeCyan = Color(0xFF00d4ff);
  static const Color primeCyanDim = Color(0xFF006680);
  static const Color primeCyanGlow = Color(0x4000d4ff);
  static const Color primeCyanFaint = Color(0x1500d4ff);

  // ── Accent Blue ──
  static const Color primeBlue = Color(0xFF3399ff);
  static const Color primeBlueDim = Color(0xFF1a4d80);

  // ── Accent Purple ──
  static const Color primePurple = Color(0xFF8855ff);
  static const Color primePurpleDim = Color(0xFF442288);

  // ── Status Colors ──
  static const Color statusOnline = Color(0xFF00cc66);
  static const Color statusActive = Color(0xFF00d4ff);
  static const Color statusBusy = Color(0xFFffaa00);
  static const Color statusError = Color(0xFFff3366);
  static const Color statusOffline = Color(0xFF334060);

  // ── Text ──
  static const Color textPrimary = Color(0xFFe8edf5);
  static const Color textSecondary = Color(0xFF8892a8);
  static const Color textMuted = Color(0xFF505a70);
  static const Color textDim = Color(0xFF353f55);

  // ── Borders ──
  static const Color borderSubtle = Color(0xFF151e30);
  static const Color borderDefault = Color(0xFF1e2a40);
  static const Color borderActive = Color(0xFF00d4ff);

  // ── Gradients ──
  static const LinearGradient bgGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [bgDeep, Color(0xFF060c18), bgDeep],
  );

  static const RadialGradient coreGlow = RadialGradient(
    colors: [
      Color(0x3000d4ff),
      Color(0x150066ff),
      Color(0x058855ff),
      Colors.transparent,
    ],
  );

  // ── Typography ──
  static const String _fontFamily = 'JetBrains Mono';

  static const TextStyle fontTech = TextStyle(
    fontFamily: _fontFamily,
    fontWeight: FontWeight.w300,
    letterSpacing: 1.2,
  );

  static const TextStyle fontCore = TextStyle(
    fontFamily: _fontFamily,
    fontWeight: FontWeight.w700,
    letterSpacing: 2.0,
  );

  static const TextStyle fontLabel = TextStyle(
    fontFamily: _fontFamily,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.8,
  );

  // ── State Helpers ──
  static Color stateColor(String state) {
    switch (state.toUpperCase()) {
      case 'ONLINE':
      case 'READY':
        return statusOnline;
      case 'LISTENING':
      case 'SPEAKING':
        return primeCyan;
      case 'THINKING':
      case 'PROCESSING':
        return primePurple;
      case 'EXECUTING':
        return primeBlue;
      case 'BUSY':
        return statusBusy;
      case 'ERROR':
      case 'ATTENTION':
        return statusError;
      case 'OFFLINE':
        return statusOffline;
      default:
        return textMuted;
    }
  }

  static Color severityColor(String severity) {
    switch (severity) {
      case 'success':
        return statusOnline;
      case 'warning':
        return statusBusy;
      case 'error':
        return statusError;
      default:
        return textSecondary;
    }
  }

  // ── ThemeData ──
  static ThemeData get darkTheme => ThemeData(
    brightness: Brightness.dark,
    fontFamily: _fontFamily,
    scaffoldBackgroundColor: bgDeep,
    colorScheme: const ColorScheme.dark(
      surface: bgSurface,
      primary: primeCyan,
      secondary: primeBlue,
      tertiary: primePurple,
      error: statusError,
      outline: borderDefault,
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: textPrimary, letterSpacing: 2.0),
      headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: textPrimary, letterSpacing: 1.5),
      headlineSmall: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: textPrimary),
      titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: textPrimary),
      titleMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textSecondary, letterSpacing: 0.5),
      bodyLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: textPrimary),
      bodyMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: textSecondary),
      bodySmall: TextStyle(fontSize: 10, fontWeight: FontWeight.w400, color: textMuted),
      labelLarge: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textPrimary, letterSpacing: 1.0),
      labelMedium: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: textSecondary, letterSpacing: 0.8),
      labelSmall: TextStyle(fontSize: 9, fontWeight: FontWeight.w400, color: textMuted, letterSpacing: 0.6),
    ),
  );
}
