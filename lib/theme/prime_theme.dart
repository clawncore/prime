import 'package:flutter/material.dart';

class PrimeTheme {
  PrimeTheme._();

  // ── Core Colors ──────────────────────────────────────────────
  static const Color surface950 = Color(0xFF0a0e1a);
  static const Color surface900 = Color(0xFF0f1525);
  static const Color surface800 = Color(0xFF151d32);
  static const Color surface700 = Color(0xFF1c2540);
  static const Color surface600 = Color(0xFF253050);
  static const Color surface500 = Color(0xFF354060);

  static const Color primeCyan = Color(0xFF00d4ff);
  static const Color primeBlue = Color(0xFF3399ff);
  static const Color primePurple = Color(0xFF8855ff);
  static const Color primeAmber = Color(0xFFffaa00);
  static const Color primeGreen = Color(0xFF33cc66);
  static const Color primeRed = Color(0xFFff3366);

  static const Color textPrimary = Color(0xFFe8edf5);
  static const Color textSecondary = Color(0xFF8892a8);
  static const Color textMuted = Color(0xFF556078);

  static const Color border = Color(0xFF1e2a40);
  static const Color borderLight = Color(0xFF253050);
  static const Color divider = Color(0xFF161e30);

  // ── Gradients ────────────────────────────────────────────────
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [surface950, surface900, Color(0xFF080c16)],
  );

  static const RadialGradient coreGlowGradient = RadialGradient(
    colors: [
      Color(0x4000d4ff),
      Color(0x203399ff),
      Color(0x108855ff),
      Colors.transparent,
    ],
  );

  // ── ThemeData ────────────────────────────────────────────────
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      fontFamily: 'JetBrains Mono',
      fontFamilyFallback: const [
        'Cascadia Code',
        'Fira Code',
        'Consolas',
        'monospace',
      ],
      colorScheme: const ColorScheme.dark(
        surface: surface900,
        surfaceContainer: surface800,
        surfaceContainerHigh: surface700,
        surfaceContainerHighest: surface600,
        primary: primeCyan,
        secondary: primeBlue,
        tertiary: primePurple,
        error: primeRed,
        onSurface: textPrimary,
        outline: border,
      ),
      scaffoldBackgroundColor: surface950,
      dividerColor: divider,
      cardColor: surface800,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: TextStyle(
          fontFamily: 'JetBrains Mono',
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: primeCyan,
          letterSpacing: 2,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface800,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: border, width: 1),
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: textPrimary,
          letterSpacing: 1,
        ),
        headlineMedium: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: textPrimary,
          letterSpacing: 1,
        ),
        headlineSmall: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          letterSpacing: 0.5,
        ),
        titleLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: textSecondary,
        ),
        bodyLarge: TextStyle(
          fontSize: 14,
          color: textPrimary,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          fontSize: 12,
          color: textSecondary,
          height: 1.4,
        ),
        bodySmall: TextStyle(
          fontSize: 10,
          color: textMuted,
        ),
        labelLarge: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: primeCyan,
          letterSpacing: 1.5,
        ),
        labelMedium: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: textSecondary,
          letterSpacing: 1,
        ),
        labelSmall: TextStyle(
          fontSize: 8,
          color: textMuted,
          letterSpacing: 1.5,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface800,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: primeCyan, width: 1.5),
        ),
        hintStyle: const TextStyle(
          color: textMuted,
          fontSize: 12,
          fontFamily: 'JetBrains Mono',
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: surface700,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: border),
        ),
        textStyle: const TextStyle(
          fontSize: 11,
          color: textPrimary,
          fontFamily: 'JetBrains Mono',
        ),
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStateProperty.all(surface600),
        trackColor: WidgetStateProperty.all(Colors.transparent),
        thickness: WidgetStateProperty.all(6),
        radius: const Radius.circular(3),
      ),
    );
  }

  // ── Helper Methods ───────────────────────────────────────────
  static Color stateColor(String state) {
    switch (state) {
      case 'ONLINE':
      case 'READY':
        return primeGreen;
      case 'LISTENING':
      case 'WAKE':
        return primeCyan;
      case 'THINKING':
      case 'ANALYSING':
        return primeBlue;
      case 'EXECUTING':
      case 'PROCESSING':
        return primePurple;
      case 'SPEAKING':
      case 'REPLY':
        return primeGreen;
      case 'ERROR':
      case 'MALFUNCTION':
        return primeRed;
      case 'WARNING':
        return primeAmber;
      case 'SLEEP':
      case 'STANDBY':
        return primeAmber;
      case 'OFFLINE':
      default:
        return textMuted;
    }
  }

  static Color severityColor(String severity) {
    switch (severity) {
      case 'critical':
      case 'error':
        return primeRed;
      case 'warning':
        return primeAmber;
      case 'success':
        return primeGreen;
      case 'info':
      default:
        return primeCyan;
    }
  }
}
