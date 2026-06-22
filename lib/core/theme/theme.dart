import 'package:flutter/material.dart';

class AppTheme {
  // ─── Core Palette ──────────────────────────────────────────────
  static const Color darkBg = Color(0xFF0A0E1A);
  static const Color darkSurface = Color(0xFF141A2E);
  static const Color darkCard = Color(0xFF1A2140);
  static const Color darkBorder = Color(0xFF2A3256);
  static const Color darkBorderLight = Color(0xFF3D4670);

  // ─── Accent Colors ─────────────────────────────────────────────
  static const Color accentLime = Color(0xFFA3E635);
  static const Color accentLimeDark = Color(0xFF65A30D);
  static const Color accentTeal = Color(0xFF22D3EE);
  static const Color accentTealDark = Color(0xFF0891B2);
  static const Color accentPurple = Color(0xFFA78BFA);
  static const Color accentOrange = Color(0xFFFB923C);
  static const Color accentPink = Color(0xFFF472B6);
  static const Color accentRose = Color(0xFFFB7185);

  // ─── Text Colors ───────────────────────────────────────────────
  static const Color textPrimary = Color(0xFFF1F5F9);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);

  // ─── Status Colors ─────────────────────────────────────────────
  static const Color successGreen = Color(0xFF34D399);
  static const Color warningAmber = Color(0xFFFBBF24);
  static const Color errorRed = Color(0xFFF87171);
  static const Color infoBlue = Color(0xFF60A5FA);

  // ─── Gradient Presets ──────────────────────────────────────────
  static const LinearGradient limeGradient = LinearGradient(
    colors: [Color(0xFFA3E635), Color(0xFF65A30D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient tealGradient = LinearGradient(
    colors: [Color(0xFF22D3EE), Color(0xFF0891B2)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient purpleGradient = LinearGradient(
    colors: [Color(0xFFA78BFA), Color(0xFF7C3AED)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient surfaceGradient = LinearGradient(
    colors: [Color(0xFF1A2140), Color(0xFF0A0E1A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF0A0E1A), Color(0xFF141A2E), Color(0xFF1A2140)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // ─── Glassmorphism Decoration ──────────────────────────────────
  static BoxDecoration glassCard({
    Color? borderColor,
    double borderRadius = 20,
    double opacity = 0.08,
  }) {
    return BoxDecoration(
      color: Colors.white.withValues(alpha: opacity),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: borderColor ?? Colors.white.withValues(alpha: 0.1),
        width: 1,
      ),
    );
  }

  static BoxDecoration premiumCard({
    Color accentColor = accentLime,
    double borderRadius = 20,
  }) {
    return BoxDecoration(
      color: darkCard,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: darkBorder,
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: accentColor.withValues(alpha: 0.05),
          blurRadius: 20,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.3),
          blurRadius: 12,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  // ─── Theme Data ────────────────────────────────────────────────
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBg,
      fontFamily: 'Segoe UI',
      colorScheme: const ColorScheme.dark(
        surface: darkSurface,
        primary: accentLime,
        secondary: accentTeal,
        tertiary: accentPurple,
        onPrimary: Colors.black,
        onSecondary: Colors.black,
        onSurface: textPrimary,
        outline: darkBorder,
        error: errorRed,
      ),
      cardTheme: CardThemeData(
        color: darkCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: darkBorder, width: 1),
          borderRadius: BorderRadius.circular(20),
        ),
        margin: EdgeInsets.zero,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: textPrimary),
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkBg.withValues(alpha: 0.7),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: darkBorder, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: darkBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: accentLime, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: errorRed, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: errorRed, width: 2),
        ),
        labelStyle: const TextStyle(
          color: textSecondary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        hintStyle: const TextStyle(color: textMuted),
        prefixIconColor: textSecondary,
        suffixIconColor: textSecondary,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentLime,
          foregroundColor: Colors.black,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 28),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          side: const BorderSide(color: darkBorder, width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 28),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accentLime,
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: darkCard,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: darkBorder),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: darkCard,
        contentTextStyle: const TextStyle(color: textPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      dividerTheme: const DividerThemeData(
        color: darkBorder,
        thickness: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: darkSurface,
        side: const BorderSide(color: darkBorder),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        labelStyle: const TextStyle(
          color: textPrimary,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: darkCard,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
    );
  }
}
