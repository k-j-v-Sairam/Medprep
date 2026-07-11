import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ─── Background & Surface Tokens ─────────────────────────────────────────
  static const Color background         = Color(0xFF080810);
  static const Color surface            = Color(0xFF13131B);
  static const Color surfaceContainer   = Color(0xFF1F1F27);
  static const Color surfaceHigh        = Color(0xFF292932);
  static const Color surfaceHighest     = Color(0xFF34343D);
  static const Color surfaceLow         = Color(0xFF1B1B23);
  static const Color surfaceLowest      = Color(0xFF0D0D15);

  // ─── Brand Palette ───────────────────────────────────────────────────────
  static const Color primary            = Color(0xFFC0C1FF); // Indigo
  static const Color primaryContainer   = Color(0xFF8083FF);
  static const Color onPrimary          = Color(0xFF1000A9);
  static const Color secondary          = Color(0xFF4FDBC8); // Teal
  static const Color secondaryContainer = Color(0xFF04B4A2);
  static const Color tertiary           = Color(0xFF4AE176); // Green
  static const Color tertiaryContainer  = Color(0xFF00A74B);
  static const Color error              = Color(0xFFFFB4AB); // Coral/Red
  static const Color errorContainer     = Color(0xFF93000A);
  static const Color onErrorContainer   = Color(0xFFFFDAD6);

  // ─── Text & Outline ──────────────────────────────────────────────────────
  static const Color onSurface          = Color(0xFFE4E1ED);
  static const Color onSurfaceVariant   = Color(0xFFC7C4D7);
  static const Color outline            = Color(0xFF908FA0);
  static const Color outlineVariant     = Color(0xFF464554);

  // ─── Semantic Aliases ────────────────────────────────────────────────────
  static const Color correctGreen       = Color(0xFF4AE176);
  static const Color incorrectRed       = Color(0xFFFFB4AB);
  static const Color neonCyan           = Color(0xFF4FDBC8); // legacy compat
  static const Color oledBlack          = background;

  // ─── Glass Layer Helper ──────────────────────────────────────────────────
  static const Color glassBorder        = Color(0x12FFFFFF); // ~7% white
  static const Color glassHighlight     = Color(0x1FFFFFFF); // ~12% white
  static const Color glassFill          = Color(0x26FFFFFF); // ~15% white

  // ─── Typography ──────────────────────────────────────────────────────────
  static TextStyle displayLg({Color? color}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: 32, fontWeight: FontWeight.w700,
        letterSpacing: -0.02 * 32, height: 1.25, color: color,
      );

  static TextStyle headlineMd({Color? color}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: 20, fontWeight: FontWeight.w600,
        height: 1.3, color: color,
      );

  static TextStyle titleSm({Color? color}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: 16, fontWeight: FontWeight.w600,
        height: 1.3, color: color,
      );

  static TextStyle bodyLg({Color? color}) =>
      GoogleFonts.inter(
        fontSize: 18, fontWeight: FontWeight.w400,
        height: 1.55, color: color,
      );

  static TextStyle bodyMd({Color? color}) =>
      GoogleFonts.inter(
        fontSize: 15, fontWeight: FontWeight.w400,
        height: 1.5, color: color,
      );

  static TextStyle labelSm({Color? color}) =>
      GoogleFonts.inter(
        fontSize: 12, fontWeight: FontWeight.w600,
        letterSpacing: 0.05 * 12, height: 1.33, color: color,
      );

  static TextStyle labelXs({Color? color}) =>
      GoogleFonts.inter(
        fontSize: 10, fontWeight: FontWeight.w700,
        letterSpacing: 1.2, height: 1.2, color: color,
      );

  // ─── Full ThemeData ───────────────────────────────────────────────────────
  static ThemeData get darkTheme {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        brightness: Brightness.dark,
        primary: primary,
        onPrimary: onPrimary,
        primaryContainer: primaryContainer,
        secondary: secondary,
        secondaryContainer: secondaryContainer,
        tertiary: tertiary,
        tertiaryContainer: tertiaryContainer,
        error: error,
        errorContainer: errorContainer,
        surface: surface,
        onSurface: onSurface,
        onSurfaceVariant: onSurfaceVariant,
        outline: outline,
        outlineVariant: outlineVariant,
      ),
      textTheme: TextTheme(
        displayLarge: displayLg(),
        headlineMedium: headlineMd(),
        titleMedium: titleSm(),
        bodyLarge: bodyLg(),
        bodyMedium: bodyMd(),
        labelSmall: labelSm(),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: primary),
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 18, fontWeight: FontWeight.w700,
          color: primary, letterSpacing: 0.5,
        ),
      ),
      cardTheme: const CardThemeData(
        color: surfaceContainer,
        elevation: 2,
        shadowColor: Color(0x1A000000), // 10% black
        margin: EdgeInsets.all(8),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        selectedItemColor: primary,
        unselectedItemColor: onSurfaceVariant.withValues(alpha: 0.5),
        elevation: 0,
        selectedLabelStyle: GoogleFonts.inter(
          fontSize: 12, fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontSize: 12, fontWeight: FontWeight.w400,
        ),
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceLowest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        hintStyle: GoogleFonts.inter(color: onSurfaceVariant.withValues(alpha: 0.5), fontSize: 15),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: onPrimary,
        elevation: 0,
        shape: CircleBorder(),
      ),
      dividerTheme: const DividerThemeData(
        color: outlineVariant,
        thickness: 1,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: secondary,
        linearMinHeight: 3,
      ),
    );
  }

  static ThemeData get lightTheme {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: const Color(0xFFF8F9FA),
      colorScheme: const ColorScheme.light(
        primary: primary,
        onPrimary: Colors.white,
        secondary: secondary,
        tertiary: tertiary,
        error: error,
        surface: Color(0xFFFFFFFF),
        onSurface: Color(0xFF1E1E1E),
        onSurfaceVariant: Color(0xFF5E5E5E),
      ),
      textTheme: TextTheme(
        displayLarge: displayLg(color: const Color(0xFF1E1E1E)),
        headlineMedium: headlineMd(color: const Color(0xFF1E1E1E)),
        titleMedium: titleSm(color: const Color(0xFF1E1E1E)),
        bodyLarge: bodyLg(color: const Color(0xFF5E5E5E)),
        bodyMedium: bodyMd(color: const Color(0xFF5E5E5E)),
        labelSmall: labelSm(color: const Color(0xFF5E5E5E)),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: primary),
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 18, fontWeight: FontWeight.w700,
          color: primary, letterSpacing: 0.5,
        ),
      ),
      cardTheme: const CardThemeData(
        color: Color(0xFFFFFFFF),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          side: BorderSide(color: Color(0x1A000000), width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        selectedItemColor: primary,
        unselectedItemColor: const Color(0xFF5E5E5E).withValues(alpha: 0.5),
        elevation: 0,
        selectedLabelStyle: GoogleFonts.inter(
          fontSize: 12, fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontSize: 12, fontWeight: FontWeight.w400,
        ),
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF0F0F0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFD0D0D0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        hintStyle: GoogleFonts.inter(color: const Color(0xFF5E5E5E).withValues(alpha: 0.5), fontSize: 15),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  // ─── Glass Box Decoration ─────────────────────────────────────────────────
  static BoxDecoration glassCard({
    double radius = 16,
    Color? borderColor,
    Color? tintColor,
    List<BoxShadow>? shadows,
  }) {
    return BoxDecoration(
      color: surfaceContainer.withValues(alpha: 0.6),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: borderColor ?? glassBorder,
        width: 1,
      ),
      boxShadow: shadows,
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          glassHighlight,
          Colors.transparent,
          if (tintColor != null) tintColor.withValues(alpha: 0.04) else Colors.transparent,
        ],
      ),
    );
  }
}

extension AppThemeExtension on BuildContext {
  bool get isDark => true; // Forced to always be dark

  Color get adaptiveSurfaceContainer => AppTheme.surfaceContainer;
  Color get adaptiveSurfaceHigh => AppTheme.surfaceHigh;
  Color get adaptiveSurfaceHighest => AppTheme.surfaceHighest;
  Color get adaptiveGlassBorder => AppTheme.glassBorder;
  Color get adaptiveBackground => AppTheme.background;
  Color get adaptiveOnSurface => AppTheme.onSurface;
  Color get adaptiveOnSurfaceVariant => AppTheme.onSurfaceVariant;
}
