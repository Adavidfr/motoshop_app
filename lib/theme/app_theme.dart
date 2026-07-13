// lib/theme/app_theme.dart

import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData get dark => _buildTheme(Brightness.dark);
  static ThemeData get light => _buildTheme(Brightness.light);

  static ThemeData _buildTheme(Brightness brightness) {
    final bool isDark = brightness == Brightness.dark;

    return ThemeData(
      useMaterial3:  true,
      brightness:    brightness,
      colorScheme:   ColorScheme(
        brightness:       brightness,
        primary:          AppColors.accent,
        onPrimary:        AppColors.onAccent,
        secondary:        AppColors.accentLight,
        onSecondary:      AppColors.onAccent,
        surface:          AppColors.surface,
        onSurface:        AppColors.textPrimary,
        error:            AppColors.error,
        onError:          Colors.white,
        outline:          AppColors.border,
        outlineVariant:   AppColors.borderLight,
      ),
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme:   AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation:       0,
        scrolledUnderElevation: 0,
        centerTitle:     false,
        titleTextStyle:  TextStyle(
          color:      AppColors.textPrimary,
          fontSize:   18,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme:     CardThemeData(
        color:        AppColors.surface,
        elevation:    0,
        shape:        const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled:           true,
        fillColor:        AppColors.surface2,
        border:           OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          borderSide:   BorderSide(color: AppColors.border),
        ),
        enabledBorder:    OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          borderSide:   BorderSide(color: AppColors.border),
        ),
        focusedBorder:    OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          borderSide:   const BorderSide(color: AppColors.accent, width: 2),
        ),
        errorBorder:      OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          borderSide:   const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          borderSide:   const BorderSide(color: AppColors.error, width: 2),
        ),
        labelStyle:       TextStyle(color: AppColors.textSecondary),
        hintStyle:        TextStyle(color: AppColors.textFaint),
        prefixIconColor:  AppColors.textSecondary,
        suffixIconColor:  AppColors.textSecondary,
      ),
      elevatedButtonTheme:  ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: AppColors.onAccent,
          minimumSize:     const Size(double.infinity, 52),
          shape:           const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          elevation:  0,
        ),
      ),
      outlinedButtonTheme:  OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          minimumSize:     const Size(double.infinity, 52),
          shape:           const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          side:      BorderSide(color: AppColors.border),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      textButtonTheme:      TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.accent,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      chipTheme:     ChipThemeData(
        backgroundColor:       AppColors.surface2,
        selectedColor:         AppColors.accent,
        labelStyle:            TextStyle(color: AppColors.textSecondary, fontSize: 12),
        secondaryLabelStyle:   const TextStyle(color: AppColors.onAccent, fontSize: 12),
        side:                  BorderSide(color: AppColors.border),
        shape:                 const StadiumBorder(),
        padding:               const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      ),
      dividerTheme:  DividerThemeData(
        color:     AppColors.border,
        thickness: 0.5,
        space:     0,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor:          AppColors.surface,
        selectedItemColor:        AppColors.accent,
        unselectedItemColor:      AppColors.textSecondary,
        selectedLabelStyle:       const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
        unselectedLabelStyle:     const TextStyle(fontSize: 11),
        elevation:                0,
      ),
      navigationDrawerTheme:    NavigationDrawerThemeData(
        backgroundColor:     AppColors.surface,
        indicatorColor:      const Color(0x1FD4A843),
        surfaceTintColor:    Colors.transparent,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor:   AppColors.surface2,
        contentTextStyle:  TextStyle(color: AppColors.textPrimary),
        behavior:          SnackBarBehavior.floating,
        shape:             const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
      textTheme:     TextTheme(
        displayLarge:  TextStyle(color: AppColors.textPrimary,   fontWeight: FontWeight.bold),
        displayMedium: TextStyle(color: AppColors.textPrimary,   fontWeight: FontWeight.bold),
        headlineLarge: TextStyle(color: AppColors.textPrimary,   fontWeight: FontWeight.bold),
        headlineMedium:TextStyle(color: AppColors.textPrimary,   fontWeight: FontWeight.bold),
        titleLarge:    TextStyle(color: AppColors.textPrimary,   fontWeight: FontWeight.bold),
        titleMedium:   TextStyle(color: AppColors.textPrimary,   fontWeight: FontWeight.w600),
        titleSmall:    TextStyle(color: AppColors.textPrimary,   fontWeight: FontWeight.w600),
        bodyLarge:     TextStyle(color: AppColors.textPrimary),
        bodyMedium:    TextStyle(color: AppColors.textSecondary),
        bodySmall:     TextStyle(color: AppColors.textSecondary, fontSize: 12),
        labelLarge:    TextStyle(color: AppColors.textPrimary,   fontWeight: FontWeight.bold),
        labelSmall:    TextStyle(color: AppColors.textSecondary, fontSize: 11),
      ),
      fontFamily:    'Roboto',
    );
  }

  AppTheme._();
}
