// lib/presentation/providers/theme_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';

class ThemeNotifier extends StateNotifier<bool> {
  ThemeNotifier() : super(true) {
    AppColors.isDark = state;
  }

  void toggleTheme() {
    state = !state;
    AppColors.isDark = state;
  }

  void setDarkTheme(bool isDark) {
    state = isDark;
    AppColors.isDark = state;
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, bool>((ref) {
  return ThemeNotifier();
});
