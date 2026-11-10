import 'package:flutter/material.dart';

/// UniNotes AI Color Palette based on "Academic Precision" Design System
/// Primary Palette:
/// - Soft Creamy White: #FAFAEF
/// - Royal Blue: #004AAD
/// - Light Blue: #AFD2FA
/// - Warm Gold: #B9915E
class AppColors {
  AppColors._();

  // Canvas & Surfaces
  static const Color surface = Color(0xFFFAFAEF);
  static const Color surfaceDim = Color(0xFFDADBD0);
  static const Color surfaceBright = Color(0xFFFAFAEF);
  static const Color surfaceLowest = Color(0xFFFFFFFF);
  static const Color surfaceLow = Color(0xFFF4F4E9);
  static const Color surfaceElevated = Color(0xFFF6F6EB);
  static const Color surfaceContainer = Color(0xFFEEEFE4);
  static const Color surfaceHigh = Color(0xFFE9E9DE);
  static const Color surfaceHighest = Color(0xFFE3E3D8);

  // Text & Content
  static const Color onSurface = Color(0xFF1A1C16);
  static const Color deepSlate = Color(0xFF1E293B);
  static const Color onSurfaceVariant = Color(0xFF64748B);
  static const Color onSurfaceSubtle = Color(0xFF434653);
  static const Color inverseSurface = Color(0xFF2F312A);
  static const Color inverseOnSurface = Color(0xFFF1F1E6);

  // Royal Blue (Primary Brand)
  static const Color primary = Color(0xFF00357F);
  static const Color primaryContainer = Color(0xFF004AAD);
  static const Color royalBlue = Color(0xFF004AAD);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onPrimaryContainer = Color(0xFFA9C1FF);
  static const Color primaryFixed = Color(0xFFD9E2FF);
  static const Color primaryFixedDim = Color(0xFFB0C6FF);
  static const Color onPrimaryFixed = Color(0xFF001945);

  // Light Blue / Ice Blue (Secondary Brand)
  static const Color secondary = Color(0xFF3E6184);
  static const Color secondaryContainer = Color(0xFFAFD2FA);
  static const Color lightBlue = Color(0xFFAFD2FA);
  static const Color secondaryIce = Color(0xFFB2D5FD);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color onSecondaryContainer = Color(0xFF395C7F);
  static const Color secondaryFixed = Color(0xFFCFE4FF);
  static const Color secondaryFixedDim = Color(0xFFA7CAF1);
  static const Color onSecondaryFixed = Color(0xFF001D34);

  // Warm Gold (Tertiary / Machine Intelligence & Gemini)
  static const Color tertiary = Color(0xFFB9915E);
  static const Color warmGold = Color(0xFFB9915E);
  static const Color tertiaryContainer = Color(0xFF69491D);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color onTertiaryContainer = Color(0xFFE6BA83);
  static const Color tertiaryFixed = Color(0xFFFFDDB6);
  static const Color tertiaryFixedDim = Color(0xFFEBBF88);
  static const Color onTertiaryFixed = Color(0xFF2A1800);
  static const Color onTertiaryFixedVariant = Color(0xFF5F4115);

  // Borders & Dividers
  static const Color outline = Color(0xFF737784);
  static const Color outlineVariant = Color(0xFFE6E8E2);
  static const Color borderSubtle = Color(0xFFE6E8E2);

  // Functional / Alert
  static const Color error = Color(0xFFBA1A1A);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onErrorContainer = Color(0xFF93000A);
  static const Color success = Color(0xFF2E7D32);
  static const Color successContainer = Color(0xFFE8F5E9);

  // Custom Gradients
  static const LinearGradient aiGoldGradient = LinearGradient(
    colors: [Color(0xFFE2B774), Color(0xFFB9915E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient lectureAccentGradient = LinearGradient(
    colors: [Color(0xFFFFDDB6), Color(0xFF004AAD), Color(0xFFAFD2FA)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
}

