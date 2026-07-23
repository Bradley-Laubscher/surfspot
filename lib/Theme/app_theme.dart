import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:surfspot/Utils/surf_scoring.dart';

/// Ocean-inspired palette shared by both the light and dark themes.
class AppColors {
  AppColors._();

  static const Color deepOcean = Color(0xFF07203A);
  static const Color midOcean = Color(0xFF0B3D5C);
  static const Color teal = Color(0xFF16A6A0);
  static const Color aqua = Color(0xFF3FD9C6);
  static const Color coral = Color(0xFFFF7A59);
  static const Color sunsetGold = Color(0xFFFFC15E);
  static const Color sand = Color(0xFFF6EFE3);
  static const Color foam = Color(0xFFFBFDFF);

  static const Color good = Color(0xFF2ECC8F);
  static const Color fair = Color(0xFFFFB74D);
  static const Color poor = Color(0xFFFF6B6B);

  static const List<Color> heroGradientLight = [Color(0xFF0B3D5C), Color(0xFF16A6A0)];
  static const List<Color> heroGradientDark = [Color(0xFF040F1F), Color(0xFF0B3D5C)];
}

Color surfRatingColor(SurfRating rating) {
  switch (rating) {
    case SurfRating.good:
      return AppColors.good;
    case SurfRating.fair:
      return AppColors.fair;
    case SurfRating.poor:
      return AppColors.poor;
  }
}

IconData surfRatingIcon(SurfRating rating) {
  switch (rating) {
    case SurfRating.good:
      return Icons.sentiment_very_satisfied_rounded;
    case SurfRating.fair:
      return Icons.sentiment_neutral_rounded;
    case SurfRating.poor:
      return Icons.sentiment_dissatisfied_rounded;
  }
}

class AppTheme {
  AppTheme._();

  static TextTheme _textTheme(Brightness brightness) {
    final base = brightness == Brightness.dark
        ? ThemeData(brightness: Brightness.dark).textTheme
        : ThemeData(brightness: Brightness.light).textTheme;
    final body = GoogleFonts.interTextTheme(base);
    return body.copyWith(
      displayLarge: GoogleFonts.poppins(textStyle: body.displayLarge, fontWeight: FontWeight.w700),
      displayMedium: GoogleFonts.poppins(textStyle: body.displayMedium, fontWeight: FontWeight.w700),
      headlineLarge: GoogleFonts.poppins(textStyle: body.headlineLarge, fontWeight: FontWeight.w700),
      headlineMedium: GoogleFonts.poppins(textStyle: body.headlineMedium, fontWeight: FontWeight.w700),
      headlineSmall: GoogleFonts.poppins(textStyle: body.headlineSmall, fontWeight: FontWeight.w600),
      titleLarge: GoogleFonts.poppins(textStyle: body.titleLarge, fontWeight: FontWeight.w600),
      titleMedium: GoogleFonts.poppins(textStyle: body.titleMedium, fontWeight: FontWeight.w600),
    );
  }

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.teal,
      brightness: Brightness.light,
      secondary: AppColors.coral,
      tertiary: AppColors.sunsetGold,
    );
    return _base(scheme, Brightness.light, AppColors.sand, AppColors.foam);
  }

  static ThemeData get dark {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.teal,
      brightness: Brightness.dark,
      secondary: AppColors.coral,
      tertiary: AppColors.sunsetGold,
    );
    return _base(scheme, Brightness.dark, AppColors.deepOcean, const Color(0xFF0F2A40));
  }

  static ThemeData _base(ColorScheme scheme, Brightness brightness, Color scaffoldBg, Color cardBg) {
    final textTheme = _textTheme(brightness);
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: scaffoldBg,
      textTheme: textTheme,
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
      ),
      cardTheme: CardThemeData(
        color: cardBg,
        elevation: 6,
        shadowColor: Colors.black.withValues(alpha: 0.25),
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surfaceContainerHighest,
        labelStyle: textTheme.labelLarge,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 68,
        backgroundColor: cardBg,
        indicatorColor: scheme.primary.withValues(alpha: 0.18),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => GoogleFonts.inter(
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
            color: states.contains(WidgetState.selected) ? scheme.primary : scheme.onSurfaceVariant,
          ),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: cardBg,
        indicatorColor: scheme.primary.withValues(alpha: 0.18),
      ),
    );
  }
}

/// Responsive breakpoints used throughout the app.
class AppBreakpoints {
  AppBreakpoints._();
  static const double tablet = 700;
  static const double desktop = 1100;

  static bool isDesktop(BuildContext context) => MediaQuery.sizeOf(context).width >= desktop;
  static bool isTablet(BuildContext context) => MediaQuery.sizeOf(context).width >= tablet;
}
