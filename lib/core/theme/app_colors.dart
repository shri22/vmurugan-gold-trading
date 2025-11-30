import 'package:flutter/material.dart';

/// App color palette for Digi Gold theme
class AppColors {

  // Main App Colors (for compatibility)
  static const Color primary = Color(0xFFFFD700); // Gold
  static const Color secondary = Color(0xFFFFA500); // Orange
  static const Color background = Color(0xFFFAFAFA); // Light background

  // Primary Gold Colors
  static const Color primaryGold = Color(0xFFFFD700); // Gold
  static const Color lightGold = Color(0xFFFFF8DC); // Cornsilk
  static const Color darkGold = Color(0xFFB8860B); // Dark Goldenrod
  static const Color metallicGold = Color(0xFFD4AF37); // Metallic Gold
  static const Color richGold = Color(0xFFFFB300); // Rich Gold
  static const Color bronzeGold = Color(0xFFCD7F32); // Bronze Gold
  static const Color champagne = Color(0xFFF7E7CE); // Light champagne

  // Dark Green Colors
  static const Color primaryGreen = Color(0xFF1B5E20); // Dark Green
  static const Color lightGreen = Color(0xFF2E7D32); // Medium Green
  static const Color darkGreen = Color(0xFF0D4E14); // Very Dark Green
  static const Color forestGreen = Color(0xFF228B22); // Forest Green
  static const Color emeraldGreen = Color(0xFF50C878); // Emerald Green

  // Silver Colors
  static const Color silver = Color(0xFFC0C0C0); // Silver
  static const Color lightSilver = Color(0xFFE5E5E5); // Light Silver
  static const Color darkSilver = Color(0xFF808080); // Dark Silver

  // Burgundy/Maroon Colors
  static const Color burgundy = Color(0xFF880E4F); // Rich Burgundy/Maroon
  static const Color lightBurgundy = Color(0xFFA31F5A); // Light Burgundy
  static const Color darkBurgundy = Color(0xFF6D0B3F); // Dark Burgundy

  // Neutral Colors
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color grey = Color(0xFF9E9E9E);
  static const Color lightGrey = Color(0xFFF5F5F5);
  static const Color darkGrey = Color(0xFF424242);

  // Status Colors (Dark Green & Gold theme)
  static const Color success = Color(0xFF2E7D32); // Dark Green for success
  static const Color error = Color(0xFFF44336);
  static const Color warning = Color(0xFFFFD700); // Gold for warning
  static const Color info = Color(0xFF1B5E20); // Dark Green for info

  // Background Colors
  static const Color backgroundLight = Color(0xFFFAFAFA);
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF1E1E1E);

  // Theme-aware color getters
  /// Returns appropriate surface color based on theme brightness
  static Color getSurfaceColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? surfaceDark
        : surfaceLight;
  }

  /// Returns appropriate background color based on theme brightness
  static Color getBackgroundColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? backgroundDark
        : backgroundLight;
  }

  /// Returns appropriate text color based on theme brightness
  static Color getTextColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? textLight
        : textPrimary;
  }

  /// Returns appropriate secondary text color based on theme brightness
  static Color getSecondaryTextColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? grey
        : textSecondary;
  }

  /// Returns appropriate card color based on theme brightness
  static Color getCardColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? surfaceDark
        : white;
  }

  /// Returns appropriate border color based on theme brightness
  static Color getBorderColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkGrey
        : lightGrey;
  }

  /// Returns appropriate shadow color based on theme brightness
  static Color getShadowColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? black.withOpacity(0.3)
        : black.withOpacity(0.1);
  }
  
  // Text Colors
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textLight = Color(0xFFFFFFFF);
  static const Color textGold = Color(0xFFB8860B);
  
  // Gradient Colors
  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFFD700),
      Color(0xFFFFA500),
      Color(0xFFB8860B),
    ],
  );

  static const LinearGradient greenGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF2E7D32),
      Color(0xFF1B5E20),
      Color(0xFF0D4E14),
    ],
  );

  static const LinearGradient goldGreenGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFFD700),
      Color(0xFF2E7D32),
      Color(0xFF1B5E20),
    ],
  );

  static const LinearGradient silverGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFC0C0C0),
      Color(0xFFA8A8A8),
      Color(0xFF808080),
    ],
  );

  static const LinearGradient silverGreenGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF757575), // Silver-grey (start)
      Color(0xFF4A5D23), // Dark green-silver mix (middle)
      Color(0xFF2E7D32), // Dark green (end)
    ],
  );
}
