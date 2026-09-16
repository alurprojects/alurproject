import 'package:flutter/material.dart';

/// ALUR Design System Color Palette (matching notebook reference UI)
abstract final class AppColors {
  // Light Mode Palette
  static const Color lightBackground = Color(0xFFEDEBE7); // Softest warm matte paper (Monday)
  static const Color lightTextPrimary = Color(0xFF22201D); // Deep charcoal
  static const Color lightTextSecondary = Color(0xFF8C8A84); // Muted gray metadata
  static const Color lightTextPlaceholder = Color(0xFFA3A19B); // "Add a new task..."
  static const Color lightCheckboxBorder = Color(0xFF454340); // 1.5px square border

  // Dark Mode Palette
  static const Color darkBackground = Color(0xFF4A4947); // Dark slate/graphite paper (Monday)
  static const Color darkTextPrimary = Color(0xFFF0EEEA); // Soft white
  static const Color darkTextSecondary = Color(0xFFA8A6A0); // Light gray metadata
  static const Color darkTextPlaceholder = Color(0xFF7A7873); // "Add a new task..."
  static const Color darkCheckboxBorder = Color(0xFF9E9C96); // 1.5px square border

  // Checked Task Accent (Orange / Terracotta)
  static const Color orangeAccent = Color(0xFFFF5722); // Vibrant warm vermilion

  // Stepped Smooth Shading for 7 Days (Monday to Sunday)
  static const List<Color> lightDayShades = [
    Color(0xFFEDEBE7), // Monday (Day 0)
    Color(0xFFE2E0DC), // Tuesday (Day 1)
    Color(0xFFD7D5CF), // Wednesday (Day 2)
    Color(0xFFCCCAC4), // Thursday (Day 3)
    Color(0xFFC1BFB9), // Friday (Day 4)
    Color(0xFFB5B3AC), // Saturday (Day 5)
    Color(0xFFAAA8A1), // Sunday (Day 6)
  ];

  static const List<Color> darkDayShades = [
    Color(0xFF4A4947), // Monday (Day 0)
    Color(0xFF403F3D), // Tuesday (Day 1)
    Color(0xFF363533), // Wednesday (Day 2)
    Color(0xFF2C2B29), // Thursday (Day 3)
    Color(0xFF232221), // Friday (Day 4)
    Color(0xFF1B1A19), // Saturday (Day 5)
    Color(0xFF131211), // Sunday (Day 6)
  ];

  // Legacy & Compatibility Aliases
  static const Color warmOffWhite = lightBackground;
  static const Color paperGray = Color(0xFFDFDDD8);
  static const Color inkBlack = Color(0xFF111111);
  static const Color charcoal = lightTextPrimary;
  static const Color warmGray = lightTextSecondary;
  static const Color hairlineGray = Color(0xFFCAC8C3);
  static const Color darkSurface = Color(0xFF454442);
  static const Color darkBorder = Color(0xFF302F2D);
  static const Color darkActiveAccent = Color(0xFFFFFFFF);
  static const Color terracotta = orangeAccent;
  static const Color infoSlate = Color(0xFF6B7280);
}
