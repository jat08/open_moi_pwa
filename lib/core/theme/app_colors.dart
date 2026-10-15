import 'package:flutter/material.dart';

class AppColors {
  // Base Core Colors
  static const Color blueCore = Color(0xFF34A4EB);         // Primary Cyan Blue
  static const Color blueContainer = Color(0xFFD1E9FF);
  static const Color blueOnContainer = Color(0xFF001D33);

  // 1. Light Theme Color Scheme
  static const ColorScheme lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: blueCore,                                  // #34A4EB
    onPrimary: Colors.white,                            // #FFFFFF
    primaryContainer: blueContainer,                    // #D1E9FF
    onPrimaryContainer: blueOnContainer,                // #001D33
    secondary: Color(0xFF00796B),                       // Deep Teal (Used for Twist Weight - TW)
    onSecondary: Colors.white,                          // #FFFFFF
    secondaryContainer: Color(0xFFB2DFDB),
    onSecondaryContainer: Color(0xFF00201A),
    surface: const Color(0xFFF4F8FC),                     // Soft Light Surface for Input Fields
    onSurface: Colors.black,                            // #000000
    surfaceVariant: Colors.white,                       // White Card Background
    onSurfaceVariant: const Color(0xFF40484C),
    outline: Color(0xFF70787D),
    error: Color(0xFFB3261E),
    onError: Colors.white,
    errorContainer: Color(0xFFF9DEDC),                  // Soft Light Rose/Pink
    onErrorContainer: Color(0xFF410E0B),                // Dark Maroon/Burgundy
  );

  // 2. Dark Theme Color Scheme
  static const ColorScheme darkColorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: blueCore,                                  // #34A4EB
    onPrimary: Colors.black,                            // #000000
    primaryContainer: Color(0xFF004977),                // Dark Blue
    onPrimaryContainer: blueContainer,                  // #D1E9FF
    secondary: Color(0xFF80CBC4),                       // Light Teal (Used for TW in Dark Mode)
    onSecondary: Colors.black,                          // #000000
    secondaryContainer: Color(0xFF005047),
    onSecondaryContainer: Color(0xFFB2DFDB),
    surface: Color(0xFF1E1E1E),                         // Dark Surface
    onSurface: Colors.white,                            // #FFFFFF
    surfaceVariant: Color(0xFF2B2B2B),                  // Dark Card Background
    onSurfaceVariant: Color(0xFFC0C7CC),
    outline: Color(0xFF8A9296),
    error: Color(0xFFF2B8B5),
    onError: Colors.black,
    errorContainer: Color(0xFF8C1D18),                  // Rich Dark Crimson/Burgundy Red
    onErrorContainer: Color(0xFFF9DEDC),                // Soft Light Rose/Pink
  );

  // 3. Custom Card Highlight Colors (Outliers & Quality Residual Errors)

  // Quality Residual Error Card Fill (fitResidual >= fitThreshold)
  static const Color errorRedLight = Color(0xFFFFEBEE);   // Soft Light Red
  static const Color errorRedDark = Color(0xFF3D1B1B);    // Soft Dark Red

  // Outlier Margin Warning Card Fill (deviation > margin threshold)
  static const Color warningYellowLight = Color(0xFFFFF9C4); // Soft Light Yellow
  static const Color warningYellowDark = Color(0xFF332D00);  // Soft Dark Yellow

  // Text Colors for Error/Warning Cards
  static const Color errorTextLight = Color(0xFFB3261E);
  static const Color errorTextDark = Color(0xFFF2B8B5);
  static const Color warningTextLight = Color(0xFF795548);
  static const Color warningTextDark = Color(0xFFFFE082);

  // Muted Subtitle / Note Colors
  static const Color noteTextLight = Color(0xFF70787D);
  static const Color noteTextDark = Color(0xFF8A9296);

  // Helper function to get card background based on state
  static Color getCardBackgroundColor({
    required BuildContext context,
    required bool isSelected,
    required bool isError,
    required bool isOutlier,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (isSelected) {
      return Theme.of(context).colorScheme.primaryContainer;
    } else if (isError) {
      return isDark ? errorRedDark : errorRedLight;
    } else if (isOutlier) {
      return isDark ? warningYellowDark : warningYellowLight;
    } else {
      return Theme.of(context).colorScheme.surfaceVariant;
    }
  }
}
