import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

/// Riverpod Theme Mode Provider
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.dark);

/// Sports Academy Design System V2.0
/// "Midnight Sapphire" Dark Theme + "Warm Ivory" Light Theme
class AppTheme {
  AppTheme._();

  // ═══════════════════════════════════════════════════════════════════
  // SPACING SYSTEM (Consistent 4pt grid)
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
  static const double radius6 = 8;
  static const double radius8 = 10;
  static const double radius10 = 12;
  static const double radius12 = 16;
  static const double radius14 = 20;
  static const double radius16 = 24;
  static const double radius20 = 24;
  static const double radius24 = 28;
  static const double radius28 = 32;
  static const double radius32 = 36;

  // ═══════════════════════════════════════════════════════════════════
  // ANIMATION DURATIONS
  // ═══════════════════════════════════════════════════════════════════
  static const Duration durationFast = Duration(milliseconds: 120);
  static const Duration durationNormal = Duration(milliseconds: 200);
  static const Duration durationSlow = Duration(milliseconds: 350);
  static const Duration durationPage = Duration(milliseconds: 300);

  // ═══════════════════════════════════════════════════════════════════
  // DARK PALETTE — Visual Reference Image 2
  // Charcoal warm slate layered surfaces with dark beige tint
  // ═══════════════════════════════════════════════════════════════════
  static const Color darkBg = Color(0xFF161513);
  static const Color darkSurface = Color(0xFF1E1C1A);
  static const Color darkCard = Color(0xFF242220);
  static const Color darkCardHover = Color(0xFF2C2A28);
  static const Color darkBorder = Color(0xFF35322F);
  static const Color darkBorderLight = Color(0xFF433F3B);
  static const Color darkBorderSubtle = Color(0xFF242220);

  // ═══════════════════════════════════════════════════════════════════
  // LIGHT PALETTE — Visual Reference Image 1
  // Warm sandy cream tones with golden undertones
  // ═══════════════════════════════════════════════════════════════════
  static const Color lightBg = Color(0xFFEFE4CE);
  static const Color lightSurface = Color(0xFFE5D9C0);
  static const Color lightCard = Color(0xFFFAF0DC);
  static const Color lightCardHover = Color(0xFFEFE4CE);
  static const Color lightBorder = Color(0xFFD3C1A5);
  static const Color lightBorderLight = Color(0xFFC0AE92);
  static const Color lightBorderSubtle = Color(0xFFFAF0DC);

  // ═══════════════════════════════════════════════════════════════════
  // ACCENT COLORS — Premium, Restrained, Warm
  // ═══════════════════════════════════════════════════════════════════

  // Primary: Premium Gold
  static const Color accentGold = Color(0xFFC67D15);
  static const Color accentGoldDark = Color(0xFFC67D15);
  static const Color accentGoldSubtle = Color(0xFFF7F1E6);

  // Secondary: Warm Terracotta / Coral
  static const Color accentCoral = Color(0xFFE76F51);
  static const Color accentCoralDark = Color(0xFFD94848);
  static const Color accentCoralSubtle = Color(0xFFFBEBE8);

  // Tertiary: Sky Blue / Ocean Blue
  static const Color accentSky = Color(0xFF38BDF8);
  static const Color accentSkyDark = Color(0xFF0284C7);
  static const Color accentSkySubtle = Color(0xFFE0F2FE);

  // Royal Purple (Chess)
  static const Color accentRoyalPurple = Color(0xFFB685FF);
  static const Color accentRoyalPurpleDark = Color(0xFF7C3AED);
  static const Color accentRoyalPurpleSubtle = Color(0xFF190F2B);

  // ─── Legacy Aliases (backward compatibility during migration) ────
  static const Color accentLime = accentGold;
  static const Color accentLimeDark = accentGoldDark;
  static const Color accentLimeSubtle = accentGoldSubtle;

  // Football -> Ocean Blue (accentSky)
  static const Color accentTeal = accentSky;
  static const Color accentTealDark = accentSkyDark;
  static const Color accentTealSubtle = accentSkySubtle;

  // Chess -> Royal Purple
  static const Color accentPurple = accentRoyalPurple;
  static const Color accentPurpleDark = accentRoyalPurpleDark;
  static const Color accentPurpleSubtle = accentRoyalPurpleSubtle;

  static const Color accentOrange = Color(0xFFFF7E40);
  static const Color accentOrangeDark = Color(0xFFEA580C);

  static const Color accentPink = Color(0xFFFF66B2);
  static const Color accentRose = Color(0xFFFDA4AF);

  // ═══════════════════════════════════════════════════════════════════
  // TEXT COLORS (Enhancing contrast and brightness)
  // ═══════════════════════════════════════════════════════════════════
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFE5E7EB);
  static const Color textMuted = Color(0xFFBCC1CA);
  static const Color textDisabled = Color(0xFF8D94A0);

  static const Color textPrimaryLight = Color(0xFF160D00);
  static const Color textSecondaryLight = Color(0xFF2D1E0B);
  static const Color textMutedLight = Color(0xFF4F402C);
  static const Color textDisabledLight = Color(0xFF756754);

  // ═══════════════════════════════════════════════════════════════════
  // STATUS COLORS
  // ═══════════════════════════════════════════════════════════════════
  static const Color successGreen = Color(0xFF22C55E);
  static const Color successGreenDark = Color(0xFF16A34A);
  static const Color warningAmber = Color(0xFFF59E0B);
  static const Color warningAmberDark = Color(0xFFD97706);
  static const Color errorRed = Color(0xFFDC2626);
  static const Color errorRedDark = Color(0xFFB91C1C);
  static const Color infoBlue = Color(0xFF38BDF8);
  static const Color infoBlueDark = Color(0xFF0284C7);

  // ═══════════════════════════════════════════════════════════════════
  // GRADIENT PRESETS (Used sparingly — hero sections & charts only)
  // ═══════════════════════════════════════════════════════════════════
  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFD4A017), Color(0xFFC67D15)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  // Legacy alias
  static const LinearGradient limeGradient = goldGradient;

  static const LinearGradient coralGradient = LinearGradient(
    colors: [Color(0xFFE76F51), Color(0xFFD94848)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient skyGradient = LinearGradient(
    colors: [Color(0xFF38BDF8), Color(0xFF0284C7)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  // Football -> Ocean Blue
  static const LinearGradient tealGradient = skyGradient;

  static const LinearGradient royalPurpleGradient = LinearGradient(
    colors: [Color(0xFFB685FF), Color(0xFF7C3AED)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  // Chess -> Royal Purple
  static const LinearGradient purpleGradient = royalPurpleGradient;

  static const LinearGradient orangeGradient = LinearGradient(
    colors: [Color(0xFFFF7E40), Color(0xFFEA580C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient greenGradient = LinearGradient(
    colors: [Color(0xFF22C55E), Color(0xFF16A34A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient redGradient = LinearGradient(
    colors: [Color(0xFFDC2626), Color(0xFFB91C1C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient blueGradient = LinearGradient(
    colors: [Color(0xFF38BDF8), Color(0xFF0284C7)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient amberGradient = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient surfaceGradient = LinearGradient(
    colors: [Color(0xFF162038), Color(0xFF0B1120)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF0B1120), Color(0xFF111B2E), Color(0xFF162038)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // ═══════════════════════════════════════════════════════════════════
  // DECORATION PRESETS
  // ═══════════════════════════════════════════════════════════════════

  /// Premium card with soft elevation — theme-aware
  static BoxDecoration premiumCard({
    Color accentColor = accentGold,
    double borderRadius = radius14,
    bool isDark = true,
  }) {
    return BoxDecoration(
      color: isDark ? darkCard : lightCard,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(color: isDark ? darkBorder : lightBorder, width: 0.6),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.06),
          blurRadius: 12,
          offset: const Offset(0, 3),
        ),
      ],
    );
  }

  /// Subtle card for secondary content — theme-aware
  static BoxDecoration subtleCard({double borderRadius = radius12, bool isDark = true}) {
    return BoxDecoration(
      color: isDark ? darkSurface : lightSurface,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(color: isDark ? darkBorderSubtle : lightBorderSubtle, width: 0.6),
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
        width: 0.6,
      ),
    );
  }

  /// Accent-highlighted card with subtle glow — theme-aware
  static BoxDecoration accentCard({
    required Color accentColor,
    double borderRadius = radius14,
    bool isDark = true,
  }) {
    return BoxDecoration(
      color: isDark ? darkCard : lightCard,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(color: accentColor.withValues(alpha: isDark ? 0.15 : 0.2), width: 0.6),
      boxShadow: [
        BoxShadow(
          color: accentColor.withValues(alpha: isDark ? 0.03 : 0.06),
          blurRadius: 12,
          offset: const Offset(0, 3),
        ),
      ],
    );
  }

  /// Input field container — theme-aware
  static BoxDecoration inputDecoration({double borderRadius = radius12, bool isDark = true}) {
    return BoxDecoration(
      color: isDark ? darkBg.withValues(alpha: 0.6) : Colors.white,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(color: isDark ? darkBorder : lightBorder, width: 0.6),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // SHADOW PRESETS (Soft, layered, not heavy)
  // ═══════════════════════════════════════════════════════════════════

  static List<BoxShadow> shadowSmall = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.08),
      blurRadius: 4,
      offset: const Offset(0, 1),
    ),
  ];

  static List<BoxShadow> shadowMedium = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.1),
      blurRadius: 8,
      offset: const Offset(0, 3),
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 2,
      offset: const Offset(0, 1),
    ),
  ];

  static List<BoxShadow> shadowLarge = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.12),
      blurRadius: 16,
      offset: const Offset(0, 6),
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
  ];

  // ═══════════════════════════════════════════════════════════════════
  // TYPOGRAPHY (Plus Jakarta Sans)
  // ═══════════════════════════════════════════════════════════════════

  static TextStyle get heading1 => GoogleFonts.plusJakartaSans(
    fontSize: 24,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.6,
    height: 1.2,
  );

  static TextStyle get heading2 => GoogleFonts.plusJakartaSans(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.4,
    height: 1.25,
  );

  static TextStyle get heading3 => GoogleFonts.plusJakartaSans(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
    height: 1.3,
  );

  static TextStyle get subtitle1 => GoogleFonts.plusJakartaSans(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.1,
    height: 1.35,
  );

  static TextStyle get subtitle2 => GoogleFonts.plusJakartaSans(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    height: 1.35,
  );

  static TextStyle get body1 => GoogleFonts.plusJakartaSans(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.45,
  );

  static TextStyle get body2 => GoogleFonts.plusJakartaSans(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.45,
  );

  static TextStyle get caption => GoogleFonts.plusJakartaSans(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    height: 1.35,
  );

  static TextStyle get overline => GoogleFonts.plusJakartaSans(
    fontSize: 10,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.8,
    height: 1.3,
  );

  static TextStyle get labelSmall => GoogleFonts.plusJakartaSans(
    fontSize: 10,
    fontWeight: FontWeight.w600,
  );

  static TextStyle get statValue => GoogleFonts.plusJakartaSans(
    fontSize: 18,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.4,
    height: 1.2,
  );

  static TextStyle get buttonText => GoogleFonts.plusJakartaSans(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.1,
  );

  // ═══════════════════════════════════════════════════════════════════
  // THEME DATA — DARK ("Midnight Sapphire")
  // ═══════════════════════════════════════════════════════════════════

  static ThemeData get darkTheme {
    final baseTextTheme = GoogleFonts.plusJakartaSansTextTheme(ThemeData.dark().textTheme);

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
        primary: accentGold,
        secondary: accentCoral,
        tertiary: accentSky,
        onPrimary: Colors.black,
        onSecondary: Colors.white,
        onSurface: textPrimary,
        outline: darkBorder,
        error: errorRed,
      ),
      cardTheme: CardThemeData(
        color: darkCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: darkBorder, width: 0.6),
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
          borderSide: const BorderSide(color: darkBorder, width: 0.6),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius12),
          borderSide: const BorderSide(color: darkBorder, width: 0.6),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius12),
          borderSide: const BorderSide(color: accentGold, width: 1.2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius12),
          borderSide: const BorderSide(color: errorRed, width: 0.6),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius12),
          borderSide: const BorderSide(color: errorRed, width: 1.2),
        ),
        labelStyle: GoogleFonts.plusJakartaSans(
          color: textSecondary,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        hintStyle: GoogleFonts.plusJakartaSans(
          color: textMuted,
          fontSize: 13,
        ),
        floatingLabelStyle: GoogleFonts.plusJakartaSans(
          color: accentGold,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        prefixIconColor: textMuted,
        suffixIconColor: textMuted,
        errorStyle: GoogleFonts.plusJakartaSans(
          color: errorRed,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentGold,
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
          side: const BorderSide(color: darkBorderLight, width: 0.6),
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
          foregroundColor: accentGold,
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          padding: const EdgeInsets.symmetric(horizontal: space10, vertical: space6),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accentGold,
        foregroundColor: Colors.black,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius12),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: darkCard,
        surfaceTintColor: Colors.transparent,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius16),
          side: const BorderSide(color: darkBorder, width: 0.6),
        ),
        titleTextStyle: heading3.copyWith(color: textPrimary),
        contentTextStyle: body2.copyWith(color: textSecondary),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: darkCard,
        contentTextStyle: GoogleFonts.plusJakartaSans(color: textPrimary, fontSize: 13),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius10),
          side: const BorderSide(color: darkBorder, width: 0.6),
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 4,
        insetPadding: const EdgeInsets.symmetric(horizontal: space12, vertical: space10),
      ),
      dividerTheme: const DividerThemeData(
        color: darkBorderSubtle,
        thickness: 0.6,
        space: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: darkSurface,
        side: const BorderSide(color: darkBorder, width: 0.6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius8),
        ),
        labelStyle: GoogleFonts.plusJakartaSans(
          color: textPrimary,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        padding: const EdgeInsets.symmetric(horizontal: space8, vertical: space4),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: accentGold,
        unselectedLabelColor: textMuted,
        labelStyle: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w500),
        indicator: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: accentGold, width: 2.0),
          ),
        ),
        dividerColor: darkBorderSubtle,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: darkCard,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(radius20)),
        ),
        dragHandleColor: darkBorderLight,
        dragHandleSize: const Size(36, 4),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return accentGold;
          return textMuted;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return accentGold.withValues(alpha: 0.3);
          return darkBorder;
        }),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: accentGold,
        linearTrackColor: darkBorder,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: darkCard,
          borderRadius: BorderRadius.circular(radius8),
          border: Border.all(color: darkBorder, width: 0.6),
        ),
        textStyle: GoogleFonts.plusJakartaSans(color: textPrimary, fontSize: 11),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: darkBg.withValues(alpha: 0.6),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radius12),
            borderSide: const BorderSide(color: darkBorder, width: 0.6),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // THEME DATA — LIGHT ("Warm Ivory")
  // ═══════════════════════════════════════════════════════════════════

  static ThemeData get lightTheme {
    final baseTextTheme = GoogleFonts.plusJakartaSansTextTheme(ThemeData.light().textTheme);

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
        labelLarge: buttonText.copyWith(color: Colors.white),
        labelSmall: labelSmall.copyWith(color: textSecondaryLight),
      ),
      colorScheme: const ColorScheme.light(
        surface: lightSurface,
        primary: accentGoldDark,
        secondary: accentCoralDark,
        tertiary: accentSkyDark,
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
          side: const BorderSide(color: lightBorder, width: 0.6),
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
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: space16, vertical: space12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius12),
          borderSide: const BorderSide(color: lightBorder, width: 0.6),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius12),
          borderSide: const BorderSide(color: lightBorder, width: 0.6),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius12),
          borderSide: const BorderSide(color: accentGoldDark, width: 1.2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius12),
          borderSide: const BorderSide(color: errorRed, width: 0.6),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius12),
          borderSide: const BorderSide(color: errorRed, width: 1.2),
        ),
        labelStyle: GoogleFonts.plusJakartaSans(
          color: textSecondaryLight,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        hintStyle: GoogleFonts.plusJakartaSans(
          color: textMutedLight,
          fontSize: 13,
        ),
        floatingLabelStyle: GoogleFonts.plusJakartaSans(
          color: accentGoldDark,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        prefixIconColor: textMutedLight,
        suffixIconColor: textMutedLight,
        errorStyle: GoogleFonts.plusJakartaSans(
          color: errorRed,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentGoldDark,
          foregroundColor: Colors.white,
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
          side: const BorderSide(color: lightBorderLight, width: 0.6),
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
          foregroundColor: accentGoldDark,
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          padding: const EdgeInsets.symmetric(horizontal: space10, vertical: space6),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accentGoldDark,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius12),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: lightCard,
        surfaceTintColor: Colors.transparent,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius16),
          side: const BorderSide(color: lightBorder, width: 0.6),
        ),
        titleTextStyle: heading3.copyWith(color: textPrimaryLight),
        contentTextStyle: body2.copyWith(color: textSecondaryLight),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: lightCard,
        contentTextStyle: GoogleFonts.plusJakartaSans(color: textPrimaryLight, fontSize: 13),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius10),
          side: const BorderSide(color: lightBorder, width: 0.6),
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 4,
        insetPadding: const EdgeInsets.symmetric(horizontal: space12, vertical: space10),
      ),
      dividerTheme: const DividerThemeData(
        color: lightBorderSubtle,
        thickness: 0.6,
        space: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: lightSurface,
        side: const BorderSide(color: lightBorder, width: 0.6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius8),
        ),
        labelStyle: GoogleFonts.plusJakartaSans(
          color: textPrimaryLight,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        padding: const EdgeInsets.symmetric(horizontal: space8, vertical: space4),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: accentGoldDark,
        unselectedLabelColor: textMutedLight,
        labelStyle: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w500),
        indicator: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: accentGoldDark, width: 2.0),
          ),
        ),
        dividerColor: lightBorderSubtle,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: lightCard,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(radius20)),
        ),
        dragHandleColor: lightBorderLight,
        dragHandleSize: const Size(36, 4),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return accentGoldDark;
          return textMutedLight;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return accentGoldDark.withValues(alpha: 0.3);
          return lightBorder;
        }),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: accentGoldDark,
        linearTrackColor: lightBorder,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: lightCard,
          borderRadius: BorderRadius.circular(radius8),
          border: Border.all(color: lightBorder, width: 0.6),
        ),
        textStyle: GoogleFonts.plusJakartaSans(color: textPrimaryLight, fontSize: 11),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: lightSurface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radius12),
            borderSide: const BorderSide(color: lightBorder, width: 0.6),
          ),
        ),
      ),
    );
  }
}
