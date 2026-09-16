import 'package:flutter/material.dart';

/// ALUR Design System Color Palette (High-contrast B&W, playful & rounded)
abstract final class AppColors {
  // Pure Black & White Foundation
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color pureBlack = Color(0xFF000000);
  static const Color mediumGray = Color(0xFF9CA3AF);
  static const Color lightGray = Color(0xFFF5F5F5);

  // Light Mode Palette
  static const Color lightBackground = Color(0xFFFFFFFF); // Pure White canvas
  static const Color lightTextPrimary = Color(0xFF000000); // Pure Black
  static const Color lightTextSecondary = Color(0xFF9CA3AF); // Medium Gray
  static const Color lightTextPlaceholder = Color(0xFF9CA3AF); // Inactive placeholder
  static const Color lightCheckboxBorder = Color(0xFF000000); // Sharp 1.5px black outline

  // Dark Mode Palette
  static const Color darkBackground = Color(0xFF000000); // Pure Black canvas
  static const Color darkTextPrimary = Color(0xFFFFFFFF); // Pure White
  static const Color darkTextSecondary = Color(0xFF9CA3AF); // Light gray metadata
  static const Color darkTextPlaceholder = Color(0xFF6B7280); // Inactive placeholder
  static const Color darkCheckboxBorder = Color(0xFFFFFFFF); // Sharp white outline

  // Checked Task Accent (Solid Black in Light Mode, Solid White in Dark Mode)
  static const Color checkedAccent = Color(0xFF000000);
  static const Color orangeAccent = Color(0xFF000000); // Unified to pure black for high-contrast B&W

  // Stepped Smooth Shading for 7 Days (Clean Monochromatic Gradient)
  static const List<Color> lightDayShades = [
    Color(0xFFFFFFFF), // Monday (Day 0)
    Color(0xFFF9F9F9), // Tuesday (Day 1)
    Color(0xFFF3F3F3), // Wednesday (Day 2)
    Color(0xFFEDEDED), // Thursday (Day 3)
    Color(0xFFE7E7E7), // Friday (Day 4)
    Color(0xFFE1E1E1), // Saturday (Day 5)
    Color(0xFFDBDBDB), // Sunday (Day 6)
  ];

  static const List<Color> darkDayShades = [
    Color(0xFF000000), // Monday (Day 0)
    Color(0xFF141414), // Tuesday (Day 1)
    Color(0xFF1F1F1F), // Wednesday (Day 2)
    Color(0xFF292929), // Thursday (Day 3)
    Color(0xFF333333), // Friday (Day 4)
    Color(0xFF3D3D3D), // Saturday (Day 5)
    Color(0xFF474747), // Sunday (Day 6)
  ];

  // Legacy & Compatibility Aliases
  static const Color warmOffWhite = lightBackground;
  static const Color paperGray = Color(0xFFF5F5F5);
  static const Color inkBlack = Color(0xFF000000);
  static const Color charcoal = lightTextPrimary;
  static const Color warmGray = lightTextSecondary;
  static const Color hairlineGray = Color(0xFFE5E7EB);
  static const Color darkSurface = Color(0xFF181818);
  static const Color darkBorder = Color(0xFF2E2E2E);
  static const Color darkActiveAccent = Color(0xFFFFFFFF);
  static const Color terracotta = Color(0xFF000000);
  static const Color infoSlate = Color(0xFF6B7280);
}
