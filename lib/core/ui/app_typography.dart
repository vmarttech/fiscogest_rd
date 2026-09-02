import 'package:flutter/material.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';

abstract class AppTypography {
  // Títulos
  static const TextStyle h1 = TextStyle(
    fontSize: 32,
    height: 1.25,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );
  static const TextStyle h2 = TextStyle(
    fontSize: 24,
    height: 1.3,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );
  static const TextStyle h3 = TextStyle(
    fontSize: 20,
    height: 1.4,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  static const TextStyle h4 = TextStyle(
    fontSize: 18,
    height: 1.45,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  static const TextStyle h4Bold = TextStyle(
    fontSize: 18,
    height: 1.45,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );
  static TextStyle h4PrimaryBold = h4Bold.copyWith(color: AppColors.primary);

  // Cuerpo de texto
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    height: 1.5,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
  );
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    height: 1.5,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
  );
  static const TextStyle bodyMediumBold = TextStyle(
    fontSize: 14,
    height: 1.5,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );
  static const TextStyle bodyMediumSemiBold = TextStyle(
    fontSize: 14,
    height: 1.5,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  static TextStyle bodyMediumSuccess = bodyMedium.copyWith(
    color: AppColors.success,
    fontWeight: FontWeight.w600,
  );
  static TextStyle bodyMediumSecondary = bodyMedium.copyWith(
    color: AppColors.textSecondary,
  );
  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    height: 1.4,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
  );

  // Etiquetas y ayudas
  static const TextStyle labelLarge = TextStyle(
    fontSize: 16,
    height: 1.25,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );
  static const TextStyle labelMedium = TextStyle(
    fontSize: 14,
    height: 1.25,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );
  static const TextStyle labelSmall = TextStyle(
    fontSize: 11,
    height: 1.2,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );
  static TextStyle labelSmallPrimaryBold = labelSmall.copyWith(
    color: AppColors.primary,
    fontWeight: FontWeight.bold,
  );
  static TextStyle labelSmallSuccessBold = labelSmall.copyWith(
    color: AppColors.success,
    fontWeight: FontWeight.w600,
  );

  // Botones
  static const TextStyle button = TextStyle(
    fontSize: 14,
    height: 1,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    color: AppColors.white,
  );

  // Estados
  static TextStyle error = bodySmall.copyWith(color: AppColors.error);
  static TextStyle disabled = bodyMedium.copyWith(
    color: AppColors.textDisabled,
  );
}
