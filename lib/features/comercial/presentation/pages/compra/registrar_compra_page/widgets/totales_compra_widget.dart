import 'package:flutter/material.dart';
import 'package:fiscogest_rd/core/ui/ui.dart';

class TotalesCompraWidget extends StatelessWidget {
  const TotalesCompraWidget({
    super.key,
    required this.subtotalSinImpuestos,
    required this.descuentoGlobal,
    required this.montoImpuesto,
    required this.totalCompra,
  });

  final double subtotalSinImpuestos;
  final double descuentoGlobal;
  final double montoImpuesto;
  final double totalCompra;


  @override
  Widget build(BuildContext context) {
    final mobile = AppBreakpoints.isMobile(context);

    return AppCard(
      borderColor: AppColors.border,
      color: AppColors.surface,
      padding: EdgeInsets.all(mobile ? AppSpacing.m : AppSpacing.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _fila('Subtotal', formatRd(subtotalSinImpuestos)),
          if (descuentoGlobal > 0)
            _fila('Descuento', formatRd(descuentoGlobal)),
          _fila('ITBIS / impuesto', formatRd(montoImpuesto)),
          AppLayout.vS,
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer.withValues(alpha: 0.35),
              borderRadius: AppRadius.allM,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total compra',
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  formatRd(totalCompra),
                  style: AppTypography.h4.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                    fontSize: mobile ? 18 : 20,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _fila(String label, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            valor,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
