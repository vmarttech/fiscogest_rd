import 'package:flutter/material.dart';
import 'package:fiscogest_rd/core/ui/app_card.dart';
import 'package:fiscogest_rd/core/ui/app_spacing.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';

class EncabezadoVenta extends StatelessWidget {
  const EncabezadoVenta({super.key, required this.numeroVenta});

  final String numeroVenta;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: AppSpacing.allM,
      elevation: 4,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Nueva Venta',
            style: AppTypography.h4.copyWith(fontWeight: FontWeight.bold),
          ),
          Text(
            'Nº $numeroVenta',
            style: AppTypography.bodyLarge.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
