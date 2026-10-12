import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: AppColors.lightColorScheme,
    scaffoldBackgroundColor: const Color(0xFFFFFFFF),
    cardTheme: CardThemeData(
      elevation: 0,
      color: AppColors.lightColorScheme.surfaceVariant,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: const Color(0xFFF7FAFE),
      indicatorColor: const Color(0xFFD8EEFF),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF34A4EB));
        }
        return const TextStyle(fontSize: 12, fontWeight: FontWeight.normal, color: Color(0xFF70787D));
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: Color(0xFF34A4EB), size: 32);
        }
        return const IconThemeData(color: Color(0xFF70787D), size: 32);
      }),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: const OutlineInputBorder(),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: AppColors.lightColorScheme.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: AppColors.lightColorScheme.primary, width: 2.0),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: AppColors.darkColorScheme,
    scaffoldBackgroundColor: const Color(0xFF121212),
    cardTheme: CardThemeData(
      elevation: 0,
      color: AppColors.darkColorScheme.surfaceVariant,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: const Color(0xFF1E1E1E),
      indicatorColor: const Color(0xFF004977),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF34A4EB));
        }
        return const TextStyle(fontSize: 12, fontWeight: FontWeight.normal, color: Color(0xFF8A9296));
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: Color(0xFF34A4EB), size: 32);
        }
        return const IconThemeData(color: Color(0xFF8A9296), size: 32);
      }),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: const OutlineInputBorder(),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: AppColors.darkColorScheme.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: AppColors.darkColorScheme.primary, width: 2.0),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
    ),
  );
}
