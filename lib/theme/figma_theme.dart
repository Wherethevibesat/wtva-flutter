import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Monochrome design tokens — Posh / Partiful inspired (black & white, shiny dark UI).
class WtvaColors {
  static const black = Color(0xFF000000);

  static const dark500 = Color(0xFF000000);
  static const dark400 = Color(0xFF121212);
  static const dark300 = Color(0xFF1C1C1C);

  static const night500 = Color(0xFF000000);
  static const night200 = Color(0xFF2E2E2E);
  static const night300 = Color(0xFF242424);

  static const neutral50 = Color(0xFFFFFFFF);
  static const neutral100 = Color(0xFFF4F4F5);
  static const neutral200 = Color(0xFFA1A1AA);
  static const neutral300 = Color(0xFF71717A);

  /// Text/icons on white surfaces (buttons, chips).
  static const onPrimary = Color(0xFF000000);

  // Semantic aliases — kept for compatibility, all map to monochrome.
  static const accentPurple = Color(0xFFFFFFFF);
  static const accentPurpleDeep = Color(0xFFFFFFFF);
  static const accentPink = Color(0xFFE4E4E7);
  static const accentBlue = Color(0xFFD4D4D8);
  static const accentGreen = Color(0xFFFAFAFA);
  static const lavender300 = Color(0xFFD4D4D8);

  static const cardElevated = Color(0xFF141414);
  static const navBlur = Color(0xE6000000);
  static const headerBlur = Color(0xCC000000);

  /// Subtle top shine (Partiful-style glow, neutral).
  static const shineOverlay = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0x14FFFFFF), Color(0x00FFFFFF)],
    stops: [0.0, 0.5],
  );

  static const rankBlueGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF3F3F46), Color(0xFFA1A1AA)],
  );

  static const rankPinkGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF52525B), Color(0xFFD4D4D8)],
  );

  static const rankPurpleGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF27272A), Color(0xFF71717A), Color(0xFFE4E4E7)],
    stops: [0.0, 0.5, 1.0],
  );

  static const rankOrangeGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF52525B), Color(0xFFE4E4E7)],
  );

  static const buttonGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFFFFF), Color(0xFFE4E4E7)],
  );

  static const fabGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFFFFF), Color(0xFFD4D4D8)],
  );

  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.5),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: Colors.white.withValues(alpha: 0.04),
          blurRadius: 0,
          spreadRadius: 0.5,
        ),
      ];

  static List<BoxShadow> get buttonShadow => [
        BoxShadow(
          color: Colors.white.withValues(alpha: 0.12),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];
}

class WtvaTheme {
  static TextTheme _textTheme(TextTheme base) {
    return GoogleFonts.interTextTheme(base).apply(
      bodyColor: WtvaColors.neutral50,
      displayColor: WtvaColors.neutral50,
    );
  }

  static ThemeData get dark {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: WtvaColors.dark500,
      splashFactory: InkSparkle.splashFactory,
      colorScheme: const ColorScheme.dark(
        primary: WtvaColors.neutral50,
        onPrimary: WtvaColors.onPrimary,
        secondary: WtvaColors.neutral200,
        surface: WtvaColors.dark400,
        onSurface: WtvaColors.neutral50,
        onSurfaceVariant: WtvaColors.neutral200,
        outline: WtvaColors.night200,
      ),
    );

    final textTheme = _textTheme(base.textTheme);

    return base.copyWith(
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStateProperty.all(WtvaColors.night200.withValues(alpha: 0.8)),
        radius: const Radius.circular(8),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: WtvaColors.dark400,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: WtvaColors.night200.withValues(alpha: 0.8)),
        ),
        contentTextStyle: GoogleFonts.inter(color: WtvaColors.neutral50, fontWeight: FontWeight.w500),
      ),
      cardTheme: CardThemeData(
        color: WtvaColors.dark400,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: WtvaColors.night200.withValues(alpha: 0.65)),
        ),
      ),
      dividerTheme: const DividerThemeData(color: WtvaColors.night200, thickness: 0.5),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: WtvaColors.neutral50,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: WtvaColors.neutral50,
          letterSpacing: -0.3,
        ),
      ),
      iconTheme: const IconThemeData(color: WtvaColors.neutral200, size: 20),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: WtvaColors.dark400,
        hintStyle: GoogleFonts.inter(fontSize: 14, color: WtvaColors.neutral300),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: WtvaColors.night200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: WtvaColors.night200.withValues(alpha: 0.9)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: WtvaColors.neutral50, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: WtvaColors.neutral50,
          foregroundColor: WtvaColors.onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: WtvaColors.neutral100,
          side: BorderSide(color: WtvaColors.night200.withValues(alpha: 0.95)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: WtvaColors.dark400,
        selectedColor: WtvaColors.neutral50,
        labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, color: WtvaColors.neutral200),
        secondaryLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, color: WtvaColors.onPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side: const BorderSide(color: WtvaColors.night200),
      ),
    );
  }
}
