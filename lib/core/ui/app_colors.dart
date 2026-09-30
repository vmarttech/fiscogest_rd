import 'package:flutter/material.dart';

abstract class AppColors {
  // ─────────────────────────────────────────────
  // PRIMARY (Teal institucional - NO azul)
  // ─────────────────────────────────────────────
  static const Color primary = Color(0xFF0F766E); // Teal-700
  static const Color primaryDark = Color(0xFF115E59); // Teal-800
  static const Color primaryLight = Color(0xFF14B8A6); // Teal-500
  static const Color primaryContainer = Color(0xFFCCFBF1); // Teal-100

  // ─────────────────────────────────────────────
  // SECONDARY
  // ─────────────────────────────────────────────
  static const Color secondary = Color(0xFF334155); // Slate-700
  static const Color secondaryLight = Color(0xFF64748B); // Slate-500

  // ─────────────────────────────────────────────
  // SEMÁNTICOS
  // ─────────────────────────────────────────────
  static const Color success = Color(0xFF10B981); // Emerald-500
  static const Color successDark = Color(0xFF059669);
  static const Color warning = Color(0xFFF59E0B); // Amber-500
  static const Color warningDark = Color(0xFFD97706);
  static const Color error = Color(0xFFEF4444); // Red-500
  static const Color errorDark = Color(0xFFDC2626);
  static const Color info = Color(0xFF6366F1); // Indigo-500 (solo info)

  // ─────────────────────────────────────────────
  // NEUTRALES
  // ─────────────────────────────────────────────
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);

  static const Color grey50 = Color(0xFFF8FAFC);
  static const Color grey100 = Color(0xFFF1F5F9);
  static const Color grey200 = Color(0xFFE2E8F0);
  static const Color grey300 = Color(0xFFCBD5E1);
  static const Color grey400 = Color(0xFF94A3B8);
  static const Color grey500 = Color(0xFF64748B);
  static const Color grey600 = Color(0xFF475569);
  static const Color grey700 = Color(0xFF334155);
  static const Color grey800 = Color(0xFF1E293B);
  static const Color grey900 = Color(0xFF0F172A);

  // ─────────────────────────────────────────────
  // FONDOS Y SUPERFICIES
  // ─────────────────────────────────────────────
  static const Color background = grey50;
  static const Color pageBackground = Color(0xFFF4F6F9);
  static const Color surface = white;
  static const Color cardBackground = white;
  static const Color darkSurface = grey800;
  static const Color sidebarBackground = grey900;

  // ─────────────────────────────────────────────
  // TEXTO
  // ─────────────────────────────────────────────
  static const Color textPrimary = grey900;
  static const Color textSecondary = grey500;
  static const Color textDisabled = grey400;
  static const Color textOnPrimary = white;
  static const Color textOnDark = grey100;

  // ─────────────────────────────────────────────
  // BORDES Y OTROS
  // ─────────────────────────────────────────────
  static const Color border = grey200;
  static const Color inputBorder = grey200;
  static const Color focusedBorder = primary;
  static const Color divider = grey800;
  static const Color tabIndicator = primaryLight;

  // Compatibilidad temporal
  static const Color white70 = Colors.white70;
  static const Color formBackground = grey50;
  static const Color focusedBlue = primary;
}
