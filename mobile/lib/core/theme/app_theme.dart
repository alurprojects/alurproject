import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

abstract final class AppTheme {
  /// Custom TextTheme mapping Inter with Black (900) & ExtraBold (800) for Title & Display styles,
  /// and Inter Regular/Medium for Body & Meta styles.
  static TextTheme _buildTextTheme(TextTheme base, Color textColor) {
    final interTextTheme = GoogleFonts.interTextTheme(base);

    return interTextTheme.copyWith(
      // Title & Display styles -> Inter Black / ExtraBold
      displayLarge: interTextTheme.displayLarge?.copyWith(
        color: textColor,
        fontWeight: FontWeight.w900,
        letterSpacing: -1.5,
      ),
      displayMedium: interTextTheme.displayMedium?.copyWith(
        color: textColor,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.0,
      ),
      displaySmall: interTextTheme.displaySmall?.copyWith(
        color: textColor,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
      ),
      headlineLarge: interTextTheme.headlineLarge?.copyWith(
        color: textColor,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
      ),
      headlineMedium: interTextTheme.headlineMedium?.copyWith(
        color: textColor,
        fontWeight: FontWeight.w700,
      ),
      headlineSmall: interTextTheme.headlineSmall?.copyWith(
        color: textColor,
        fontWeight: FontWeight.w700,
      ),
      titleLarge: interTextTheme.titleLarge?.copyWith(
        color: textColor,
        fontWeight: FontWeight.w700,
      ),
      titleMedium: interTextTheme.titleMedium?.copyWith(
        color: textColor,
        fontWeight: FontWeight.w600,
      ),
      titleSmall: interTextTheme.titleSmall?.copyWith(
        color: textColor,
        fontWeight: FontWeight.w600,
      ),

      // Body & Label styles -> Inter
      bodyLarge: interTextTheme.bodyLarge?.copyWith(color: textColor),
      bodyMedium: interTextTheme.bodyMedium?.copyWith(color: textColor),
      bodySmall: interTextTheme.bodySmall?.copyWith(color: textColor),
      labelLarge: interTextTheme.labelLarge?.copyWith(color: textColor),
      labelMedium: interTextTheme.labelMedium?.copyWith(color: textColor),
      labelSmall: interTextTheme.labelSmall?.copyWith(color: textColor),
    );
  }

  /// Helper method to create Inter title style
  static TextStyle titleStyle({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? letterSpacing,
    double? height,
  }) {
    return GoogleFonts.inter(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  static ThemeData get lightTheme {
    final textTheme = _buildTextTheme(ThemeData.light().textTheme, AppColors.lightTextPrimary);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.lightBackground,
      colorScheme: const ColorScheme.light(
        surface: AppColors.lightBackground,
        primary: AppColors.lightTextPrimary,
        onPrimary: Colors.white,
        onSurface: AppColors.lightTextPrimary,
      ),
      textTheme: textTheme,
      dividerColor: Colors.transparent,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.lightBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: AppColors.lightTextPrimary),
        titleTextStyle: GoogleFonts.inter(
          color: AppColors.lightTextPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    final textTheme = _buildTextTheme(ThemeData.dark().textTheme, AppColors.darkTextPrimary);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.darkBackground,
      colorScheme: const ColorScheme.dark(
        surface: AppColors.darkBackground,
        primary: AppColors.pureWhite,
        onPrimary: Colors.black,
        onSurface: AppColors.pureWhite,
      ),
      textTheme: textTheme,
      dividerColor: Colors.transparent,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.darkBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: AppColors.darkTextPrimary),
        titleTextStyle: GoogleFonts.inter(
          color: AppColors.darkTextPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
