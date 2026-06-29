import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

/// Riverpod Theme Mode Provider
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.dark);

/// Sports Academy Design System — Refined Premium OLED Obsidian & Cool Light Theme
class AppTheme {
  AppTheme._();

  // ═══════════════════════════════════════════════════════════════════
  // SPACING SYSTEM (Compact & Dense)
  // ═══════════════════════════════════════════════════════════════════
  static const double space2 = 2;
  static const double space4 = 4;
  static const double space6 = 6;
  static const double space8 = 8;
  static const double space10 = 10;
  static const double space12 = 12;
  static const double space14 = 14;
  static const double space16 = 16;
  static const double space20 = 20;
  static const double space24 = 24;
  static const double space28 = 28;
  static const double space32 = 32;
  static const double space40 = 40;
  static const double space48 = 48;
  static const double space56 = 56;
  static const double space64 = 64;

  // ═══════════════════════════════════════════════════════════════════
  // BORDER RADIUS SYSTEM
  // ═══════════════════════════════════════════════════════════════════
  static const double radius6 = 6;
  static const double radius8 = 8;
  static const double radius10 = 10;
  static const double radius12 = 12;
  static const double radius14 = 14;
  static const double radius16 = 16;
  static const double radius20 = 20;
  static const double radius24 = 24;
  static const double radius28 = 28;
  static const double radius32 = 32;

  // ═══════════════════════════════════════════════════════════════════
  // ANIMATION DURATIONS
  // ═══════════════════════════════════════════════════════════════════
  static const Duration durationFast = Duration(milliseconds: 120);
  static const Duration durationNormal = Duration(milliseconds: 200);
  static const Duration durationSlow = Duration(milliseconds: 350);
  static const Duration durationPage = Duration(milliseconds: 250);

  // ═══════════════════════════════════════════════════════════════════
  // CORE PALETTE — Obsidian OLED Dark Theme
  // ═══════════════════════════════════════════════════════════════════
  static const Color darkBg = Color(0xFF050508);
  static const Color darkSurface = Color(0xFF0C0E14);
  static const Color darkCard = Color(0xFF11131C);
  static const Color darkCardHover = Color(0xFF171A27);
  static const Color darkBorder = Color(0xFF1A1D2B);
  static const Color darkBorderLight = Color(0xFF282C40);
  static const Color darkBorderSubtle = Color(0xFF121522);

  // ═══════════════════════════════════════════════════════════════════
  // CORE PALETTE — Premium Cool Light Theme
  // ═══════════════════════════════════════════════════════════════════
  static const Color lightBg = Color(0xFFF8FAFC);
  static const Color lightSurface = Color(0xFFF1F5F9);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightCardHover = Color(0xFFF8FAFC);
  static const Color lightBorder = Color(0xFFE2E8F0);
  static const Color lightBorderLight = Color(0xFFCBD5E1);
  static const Color lightBorderSubtle = Color(0xFFF1F5F9);

  // ═══════════════════════════════════════════════════════════════════
  // ACCENT COLORS (Vibrant Cyber Neon & HighLegibility Light mode equivalents)
  // ═══════════════════════════════════════════════════════════════════
  static const Color accentLime = Color(0xFFD6FF38);
  static const Color accentLimeDark = Color(0xFF86EF00);
  static const Color accentLimeSubtle = Color(0xFF162205);

  static const Color accentTeal = Color(0xFF00FFCC);
  static const Color accentTealDark = Color(0xFF0D9488);
  static const Color accentTealSubtle = Color(0xFF04211D);

  static const Color accentPurple = Color(0xFFB685FF);
  static const Color accentPurpleDark = Color(0xFF7C3AED);
  static const Color accentPurpleSubtle = Color(0xFF190F2B);

  static const Color accentOrange = Color(0xFFFF7E40);
  static const Color accentOrangeDark = Color(0xFFEA580C);

  static const Color accentPink = Color(0xFFFF66B2);
  static const Color accentRose = Color(0xFFFDA4AF);

  // ═══════════════════════════════════════════════════════════════════
  // TEXT COLORS
  // ═══════════════════════════════════════════════════════════════════
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);
  static const Color textDisabled = Color(0xFF334155);

  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF475569);
  static const Color textMutedLight = Color(0xFF64748B);
  static const Color textDisabledLight = Color(0xFF94A3B8);

  // ═══════════════════════════════════════════════════════════════════
  // STATUS COLORS
  // ═══════════════════════════════════════════════════════════════════
  static const Color successGreen = Color(0xFF10B981);
  static const Color successGreenDark = Color(0xFF047857);
  static const Color warningAmber = Color(0xFFF59E0B);
  static const Color warningAmberDark = Color(0xFFB45309);
  static const Color errorRed = Color(0xFFEF4444);
  static const Color errorRedDark = Color(0xFFB91C1C);
  static const Color infoBlue = Color(0xFF3B82F6);
  static const Color infoBlueDark = Color(0xFF1D4ED8);

  // ═══════════════════════════════════════════════════════════════════
  // GRADIENT PRESETS
  // ═══════════════════════════════════════════════════════════════════
  static const LinearGradient limeGradient = LinearGradient(
    colors: [Color(0xFFD6FF38), Color(0xFF86EF00)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient tealGradient = LinearGradient(
    colors: [Color(0xFF00FFCC), Color(0xFF0D9488)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient purpleGradient = LinearGradient(
    colors: [Color(0xFFB685FF), Color(0xFF7C3AED)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient orangeGradient = LinearGradient(
    colors: [Color(0xFFFF7E40), Color(0xFFEA580C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient greenGradient = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF047857)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient redGradient = LinearGradient(
    colors: [Color(0xFFEF4444), Color(0xFFB91C1C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient blueGradient = LinearGradient(
    colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient amberGradient = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFB45309)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient surfaceGradient = LinearGradient(
    colors: [Color(0xFF11131C), Color(0xFF050508)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF050508), Color(0xFF0C0E14), Color(0xFF11131C)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // ═══════════════════════════════════════════════════════════════════
  // DECORATION PRESETS
  // ═══════════════════════════════════════════════════════════════════

  /// Standard premium card with subtle border and shadow
  static BoxDecoration premiumCard({
    Color accentColor = accentLime,
    double borderRadius = radius14,
  }) {
    return BoxDecoration(
      color: darkCard,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(color: darkBorder, width: 0.8),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.4),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  /// Subtle card for secondary content
  static BoxDecoration subtleCard({double borderRadius = radius12}) {
    return BoxDecoration(
      color: darkSurface,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(color: darkBorderSubtle, width: 0.8),
    );
  }

  /// Glass morphism card
  static BoxDecoration glassCard({
    Color? borderColor,
    double borderRadius = radius14,
    double opacity = 0.05,
  }) {
    return BoxDecoration(
      color: Colors.white.withValues(alpha: opacity),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: borderColor ?? Colors.white.withValues(alpha: 0.05),
        width: 0.8,
      ),
    );
  }

  /// Accent-highlighted card with glow
  static BoxDecoration accentCard({
    required Color accentColor,
    double borderRadius = radius14,
  }) {
    return BoxDecoration(
      color: darkCard,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(color: accentColor.withValues(alpha: 0.2), width: 0.8),
      boxShadow: [
        BoxShadow(
          color: accentColor.withValues(alpha: 0.04),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  /// Input field container
  static BoxDecoration inputDecoration({double borderRadius = radius12}) {
    return BoxDecoration(
      color: darkBg.withValues(alpha: 0.8),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(color: darkBorder, width: 0.8),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // SHADOW PRESETS
  // ═══════════════════════════════════════════════════════════════════

  static List<BoxShadow> shadowSmall = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.2),
      blurRadius: 4,
      offset: const Offset(0, 1),
    ),
  ];

  static List<BoxShadow> shadowMedium = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.35),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> shadowLarge = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.5),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];

  // ═══════════════════════════════════════════════════════════════════
  // TYPOGRAPHY (using Google Fonts Inter)
  // ═══════════════════════════════════════════════════════════════════

  static TextStyle get heading1 => GoogleFonts.inter(
    fontSize: 24,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.6,
    height: 1.2,
  );

  static TextStyle get heading2 => GoogleFonts.inter(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.4,
    height: 1.25,
  );

  static TextStyle get heading3 => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
    height: 1.3,
  );

  static TextStyle get subtitle1 => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.1,
    height: 1.35,
  );

  static TextStyle get subtitle2 => GoogleFonts.inter(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    height: 1.35,
  );

  static TextStyle get body1 => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.45,
  );

  static TextStyle get body2 => GoogleFonts.inter(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.45,
  );

  static TextStyle get caption => GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    height: 1.35,
  );

  static TextStyle get overline => GoogleFonts.inter(
    fontSize: 10,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.8,
    height: 1.3,
  );

  static TextStyle get labelSmall => GoogleFonts.inter(
    fontSize: 10,
    fontWeight: FontWeight.w600,
  );

  static TextStyle get statValue => GoogleFonts.inter(
    fontSize: 18,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.4,
    height: 1.2,
  );

  static TextStyle get buttonText => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.1,
  );

  // ═══════════════════════════════════════════════════════════════════
  // THEME DATA — DARK
  // ═══════════════════════════════════════════════════════════════════

  static ThemeData get darkTheme {
    final baseTextTheme = GoogleFonts.interTextTheme(ThemeData.dark().textTheme);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBg,
      textTheme: baseTextTheme.copyWith(
        displayLarge: heading1.copyWith(color: textPrimary),
        displayMedium: heading2.copyWith(color: textPrimary),
        displaySmall: heading3.copyWith(color: textPrimary),
        titleLarge: subtitle1.copyWith(color: textPrimary),
        titleMedium: subtitle2.copyWith(color: textPrimary),
        bodyLarge: body1.copyWith(color: textPrimary),
        bodyMedium: body2.copyWith(color: textSecondary),
        bodySmall: caption.copyWith(color: textMuted),
        labelLarge: buttonText.copyWith(color: Colors.black),
        labelSmall: labelSmall.copyWith(color: textSecondary),
      ),
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
          side: const BorderSide(color: darkBorder, width: 0.8),
          borderRadius: BorderRadius.circular(radius14),
        ),
        margin: EdgeInsets.zero,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: textPrimary, size: 20),
        titleTextStyle: heading2.copyWith(color: textPrimary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkBg.withValues(alpha: 0.6),
        contentPadding: const EdgeInsets.symmetric(horizontal: space16, vertical: space12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius12),
          borderSide: const BorderSide(color: darkBorder, width: 0.8),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius12),
          borderSide: const BorderSide(color: darkBorder, width: 0.8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius12),
          borderSide: const BorderSide(color: accentLime, width: 1.2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius12),
          borderSide: const BorderSide(color: errorRed, width: 0.8),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius12),
          borderSide: const BorderSide(color: errorRed, width: 1.2),
        ),
        labelStyle: GoogleFonts.inter(
          color: textSecondary,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        hintStyle: GoogleFonts.inter(
          color: textMuted,
          fontSize: 13,
        ),
        floatingLabelStyle: GoogleFonts.inter(
          color: accentLime,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        prefixIconColor: textMuted,
        suffixIconColor: textMuted,
        errorStyle: GoogleFonts.inter(
          color: errorRed,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentLime,
          foregroundColor: Colors.black,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: space12, horizontal: space20),
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius12),
          ),
          textStyle: buttonText,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          side: const BorderSide(color: darkBorderLight, width: 0.8),
          padding: const EdgeInsets.symmetric(vertical: space12, horizontal: space20),
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius12),
          ),
          textStyle: buttonText,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accentLime,
          textStyle: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          padding: const EdgeInsets.symmetric(horizontal: space10, vertical: space6),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accentLime,
        foregroundColor: Colors.black,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius12),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: darkCard,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius16),
          side: const BorderSide(color: darkBorder, width: 0.8),
        ),
        titleTextStyle: heading3.copyWith(color: textPrimary),
        contentTextStyle: body2.copyWith(color: textSecondary),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: darkCard,
        contentTextStyle: GoogleFonts.inter(color: textPrimary, fontSize: 13),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius10),
          side: const BorderSide(color: darkBorder, width: 0.8),
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 6,
        insetPadding: const EdgeInsets.symmetric(horizontal: space12, vertical: space10),
      ),
      dividerTheme: const DividerThemeData(
        color: darkBorderSubtle,
        thickness: 0.8,
        space: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: darkSurface,
        side: const BorderSide(color: darkBorder, width: 0.8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius8),
        ),
        labelStyle: GoogleFonts.inter(
          color: textPrimary,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        padding: const EdgeInsets.symmetric(horizontal: space8, vertical: space4),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: accentLime,
        unselectedLabelColor: textMuted,
        labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
        indicator: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: accentLime, width: 2.0),
          ),
        ),
        dividerColor: darkBorderSubtle,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: darkCard,
        surfaceTintColor: Colors.transparent,
        elevation: 12,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(radius16)),
        ),
        dragHandleColor: darkBorderLight,
        dragHandleSize: const Size(36, 4),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return accentLime;
          return textMuted;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return accentLime.withValues(alpha: 0.3);
          return darkBorder;
        }),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: accentLime,
        linearTrackColor: darkBorder,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: darkCard,
          borderRadius: BorderRadius.circular(radius6),
          border: Border.all(color: darkBorder, width: 0.8),
        ),
        textStyle: GoogleFonts.inter(color: textPrimary, fontSize: 11),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // THEME DATA — LIGHT
  // ═══════════════════════════════════════════════════════════════════

  static ThemeData get lightTheme {
    final baseTextTheme = GoogleFonts.interTextTheme(ThemeData.light().textTheme);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: lightBg,
      textTheme: baseTextTheme.copyWith(
        displayLarge: heading1.copyWith(color: textPrimaryLight),
        displayMedium: heading2.copyWith(color: textPrimaryLight),
        displaySmall: heading3.copyWith(color: textPrimaryLight),
        titleLarge: subtitle1.copyWith(color: textPrimaryLight),
        titleMedium: subtitle2.copyWith(color: textPrimaryLight),
        bodyLarge: body1.copyWith(color: textPrimaryLight),
        bodyMedium: body2.copyWith(color: textSecondaryLight),
        bodySmall: caption.copyWith(color: textMutedLight),
        labelLarge: buttonText.copyWith(color: Colors.black),
        labelSmall: labelSmall.copyWith(color: textSecondaryLight),
      ),
      colorScheme: const ColorScheme.light(
        surface: lightSurface,
        primary: accentLimeDark,
        secondary: accentTealDark,
        tertiary: accentPurpleDark,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimaryLight,
        outline: lightBorder,
        error: errorRed,
      ),
      cardTheme: CardThemeData(
        color: lightCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: lightBorder, width: 0.8),
          borderRadius: BorderRadius.circular(radius14),
        ),
        margin: EdgeInsets.zero,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: textPrimaryLight, size: 20),
        titleTextStyle: heading2.copyWith(color: textPrimaryLight),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: space16, vertical: space12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius12),
          borderSide: const BorderSide(color: lightBorder, width: 0.8),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius12),
          borderSide: const BorderSide(color: lightBorder, width: 0.8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius12),
          borderSide: const BorderSide(color: accentLimeDark, width: 1.2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius12),
          borderSide: const BorderSide(color: errorRed, width: 0.8),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius12),
          borderSide: const BorderSide(color: errorRed, width: 1.2),
        ),
        labelStyle: GoogleFonts.inter(
          color: textSecondaryLight,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        hintStyle: GoogleFonts.inter(
          color: textMutedLight,
          fontSize: 13,
        ),
        floatingLabelStyle: GoogleFonts.inter(
          color: accentLimeDark,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        prefixIconColor: textMutedLight,
        suffixIconColor: textMutedLight,
        errorStyle: GoogleFonts.inter(
          color: errorRed,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentLimeDark,
          foregroundColor: Colors.black,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: space12, horizontal: space20),
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius12),
          ),
          textStyle: buttonText,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimaryLight,
          side: const BorderSide(color: lightBorderLight, width: 0.8),
          padding: const EdgeInsets.symmetric(vertical: space12, horizontal: space20),
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius12),
          ),
          textStyle: buttonText,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accentLimeDark,
          textStyle: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          padding: const EdgeInsets.symmetric(horizontal: space10, vertical: space6),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accentLimeDark,
        foregroundColor: Colors.white,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius12),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: lightCard,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius16),
          side: const BorderSide(color: lightBorder, width: 0.8),
        ),
        titleTextStyle: heading3.copyWith(color: textPrimaryLight),
        contentTextStyle: body2.copyWith(color: textSecondaryLight),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: lightCard,
        contentTextStyle: GoogleFonts.inter(color: textPrimaryLight, fontSize: 13),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius10),
          side: const BorderSide(color: lightBorder, width: 0.8),
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 6,
        insetPadding: const EdgeInsets.symmetric(horizontal: space12, vertical: space10),
      ),
      dividerTheme: const DividerThemeData(
        color: lightBorderSubtle,
        thickness: 0.8,
        space: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: lightSurface,
        side: const BorderSide(color: lightBorder, width: 0.8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius8),
        ),
        labelStyle: GoogleFonts.inter(
          color: textPrimaryLight,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        padding: const EdgeInsets.symmetric(horizontal: space8, vertical: space4),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: accentLimeDark,
        unselectedLabelColor: textMutedLight,
        labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
        indicator: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: accentLimeDark, width: 2.0),
          ),
        ),
        dividerColor: lightBorderSubtle,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: lightCard,
        surfaceTintColor: Colors.transparent,
        elevation: 12,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(radius16)),
        ),
        dragHandleColor: lightBorderLight,
        dragHandleSize: const Size(36, 4),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return accentLimeDark;
          return textMutedLight;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return accentLimeDark.withValues(alpha: 0.3);
          return lightBorder;
        }),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: accentLimeDark,
        linearTrackColor: lightBorder,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: lightCard,
          borderRadius: BorderRadius.circular(radius6),
          border: Border.all(color: lightBorder, width: 0.8),
        ),
        textStyle: GoogleFonts.inter(color: textPrimaryLight, fontSize: 11),
      ),
    );
  }
}
