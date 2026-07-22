import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Light design tokens aligned with the WTVA customer web app
/// (page #f6f6f9, white cards, purple→magenta accent).
///
/// Token names (`dark*`, `night*`) are kept for compatibility with existing
/// screens; values are light-theme surfaces/borders.
class WtvaColors {
  static const black = Color(0xFF0F1115);

  /// Page background (web `--wtva-page`).
  static const dark500 = Color(0xFFF6F6F9);

  /// Card / panel surface (web `--wtva-card`).
  static const dark400 = Color(0xFFFFFFFF);

  /// Elevated / chip surface (web `--wtva-dark-400`).
  static const dark300 = Color(0xFFF2F2F6);

  static const night500 = Color(0xFF0F1115);

  /// Borders / hairlines (web `--wtva-dark-300`).
  static const night200 = Color(0xFFE6E6EE);
  static const night300 = Color(0xFFE6E6EE);

  /// Primary ink (web `--wtva-ink`) — used where screens previously used white text.
  static const neutral50 = Color(0xFF0F1115);
  static const neutral100 = Color(0xFF18181B);

  /// Muted text (web `--wtva-muted`).
  static const neutral200 = Color(0xFF52525B);

  /// Subtle text (web `--wtva-subtle`).
  static const neutral300 = Color(0xFF71717A);

  /// Text/icons on accent / gradient buttons.
  static const onPrimary = Color(0xFFFFFFFF);

  // Brand accent — purple → magenta (web)
  static const accentPurple = Color(0xFF8B2FE0);
  static const accentPurpleDeep = Color(0xFF7C3AED);
  static const accentPink = Color(0xFFDB2777);
  static const accentBlue = Color(0xFF7C3AED);
  static const accentGreen = Color(0xFF059669);
  static const lavender300 = Color(0xFFA21CAF);

  static const cardElevated = Color(0xFFFFFFFF);
  static const navBlur = Color(0xF2FFFFFF);
  static const headerBlur = Color(0xE6FFFFFF);

  static const shineOverlay = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0x14FFFFFF), Color(0x00FFFFFF)],
    stops: [0.0, 0.5],
  );

  static const rankBlueGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF7C3AED), Color(0xFF8B2FE0)],
  );

  static const rankPinkGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFA21CAF), Color(0xFFDB2777)],
  );

  static const rankPurpleGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF7C3AED), Color(0xFFA21CAF), Color(0xFFDB2777)],
    stops: [0.0, 0.5, 1.0],
  );

  static const rankOrangeGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF8B2FE0), Color(0xFFDB2777)],
  );

  static const buttonGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF7C3AED), Color(0xFFA21CAF), Color(0xFFDB2777)],
  );

  /// Immersive splash / onboarding / auth atmosphere (same realm as home hero).
  static const brandBackdropGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF2A0B45),
      Color(0xFF3B0764),
      Color(0xFF4A044E),
      Color(0xFF831843),
    ],
    stops: [0.0, 0.35, 0.7, 1.0],
  );

  static const fabGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF7C3AED), Color(0xFFA21CAF), Color(0xFFDB2777)],
  );

  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: const Color(0xFF101115).withValues(alpha: 0.04),
          blurRadius: 2,
          offset: const Offset(0, 1),
        ),
        BoxShadow(
          color: const Color(0xFF101115).withValues(alpha: 0.06),
          blurRadius: 30,
          offset: const Offset(0, 10),
        ),
      ];

  static List<BoxShadow> get buttonShadow => [
        BoxShadow(
          color: const Color(0xFF7C3AED).withValues(alpha: 0.35),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ];
}

class WtvaTheme {
  static TextTheme _textTheme(TextTheme base) {
    return GoogleFonts.urbanistTextTheme(base).apply(
      bodyColor: WtvaColors.neutral50,
      displayColor: WtvaColors.neutral50,
    );
  }

  /// Light theme matching the customer web app.
  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: WtvaColors.dark500,
      splashFactory: InkSparkle.splashFactory,
      colorScheme: const ColorScheme.light(
        primary: WtvaColors.accentPurple,
        onPrimary: WtvaColors.onPrimary,
        secondary: WtvaColors.accentPink,
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
        thumbColor: WidgetStateProperty.all(WtvaColors.neutral300.withValues(alpha: 0.8)),
        radius: const Radius.circular(8),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: WtvaColors.neutral50,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentTextStyle: GoogleFonts.urbanist(
          color: WtvaColors.onPrimary,
          fontWeight: FontWeight.w500,
        ),
      ),
      cardTheme: CardThemeData(
        color: WtvaColors.dark400,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: WtvaColors.night200),
        ),
      ),
      dividerTheme: const DividerThemeData(color: WtvaColors.night200, thickness: 0.5),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        iconColor: WtvaColors.neutral200,
        textColor: WtvaColors.neutral50,
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: WtvaColors.dark500,
        foregroundColor: WtvaColors.neutral50,
        titleTextStyle: GoogleFonts.urbanist(
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
        hintStyle: GoogleFonts.urbanist(fontSize: 14, color: WtvaColors.neutral300),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: WtvaColors.night200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: WtvaColors.night200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: WtvaColors.accentPurple, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: WtvaColors.accentPurple,
          foregroundColor: WtvaColors.onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          textStyle: GoogleFonts.urbanist(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: WtvaColors.neutral50,
          side: const BorderSide(color: WtvaColors.night200),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: WtvaColors.dark300,
        selectedColor: WtvaColors.accentPurple.withValues(alpha: 0.12),
        labelStyle: GoogleFonts.urbanist(fontWeight: FontWeight.w600, color: WtvaColors.neutral200),
        secondaryLabelStyle: GoogleFonts.urbanist(
          fontWeight: FontWeight.w600,
          color: WtvaColors.accentPurple,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side: const BorderSide(color: WtvaColors.night200),
      ),
    );
  }

  /// @Deprecated — use [light]. Kept so older references compile during migration.
  static ThemeData get dark => light;
}
