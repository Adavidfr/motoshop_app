// lib/theme/app_colors.dart

import 'package:flutter/material.dart';

class AppColors {
  // ── Fondos (Negro Predominante) ───────────────────────────
  static const Color background  = Color(0xFF000000);
  static const Color surface     = Color(0xFF121212);
  static const Color surface2    = Color(0xFF1E1E1E);
  static const Color border      = Color(0xFF2E2E2E);
  static const Color borderLight = Color(0xFF222222);

  // ── Texto (Blancos e Intermedios) ─────────────────────────
  static const Color textPrimary   = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B0B0);
  static const Color textFaint     = Color(0xFF555555);

  // ── Accent (Rojo Deportivo) ───────────────────────────────
  static const Color accent      = Color(0xFFE50914);
  static const Color accentLight = Color(0xFFFF3B30);
  static const Color accentDark  = Color(0xFFB30006);
  static const Color onAccent    = Color(0xFFFFFFFF);

  // ── Semánticos ────────────────────────────────────────────
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error   = Color(0xFFEF4444);
  static const Color info    = Color(0xFF3B82F6);

  AppColors._();
}
