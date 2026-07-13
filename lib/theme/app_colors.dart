// lib/theme/app_colors.dart

import 'package:flutter/material.dart';

class AppColors {
  static bool isDark = true;

  // ── Fondos ───────────────────────────────────────────────
  static Color get background  => isDark ? const Color(0xFF000000) : const Color(0xFFF5F5F7);
  static Color get surface     => isDark ? const Color(0xFF121212) : const Color(0xFFFFFFFF);
  static Color get surface2    => isDark ? const Color(0xFF1E1E1E) : const Color(0xFFEAEAEF);
  static Color get border      => isDark ? const Color(0xFF2E2E2E) : const Color(0xFFDCDCE2);
  static Color get borderLight => isDark ? const Color(0xFF222222) : const Color(0xFFEBEBEF);

  // ── Texto ────────────────────────────────────────────────
  static Color get textPrimary   => isDark ? const Color(0xFFFFFFFF) : const Color(0xFF1D1D1F);
  static Color get textSecondary => isDark ? const Color(0xFFB0B0B0) : const Color(0xFF6E6E73);
  static Color get textFaint     => isDark ? const Color(0xFF555555) : const Color(0xFF86868B);

  // ── Accent (Rojo Deportivo) ──────────────────────────────
  static const Color accent      = Color(0xFFE50914);
  static const Color accentLight = Color(0xFFFF3B30);
  static const Color accentDark  = Color(0xFFB30006);
  static const Color onAccent    = Color(0xFFFFFFFF);

  // ── Semánticos ───────────────────────────────────────────
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error   = Color(0xFFEF4444);
  static const Color info    = Color(0xFF3B82F6);

  AppColors._();
}
