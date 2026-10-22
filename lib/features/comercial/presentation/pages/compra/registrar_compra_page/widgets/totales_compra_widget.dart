import 'package:flutter/material.dart';
import 'package:fiscogest_rd/core/ui/ui.dart';

class TotalesCompraWidget extends StatelessWidget {
  const TotalesCompraWidget({
    super.key,
    required this.subtotalSinImpuestos,
    required this.descuentoGlobal,
    required this.montoImpuesto,
    required this.totalCompra,
    this.mostrarImpuesto = true,
    this.observacionesController,
    this.retencion = 0,
  });

  final double subtotalSinImpuestos;
  final double descuentoGlobal;
  final double montoImpuesto;
  final double totalCompra;
  final bool mostrarImpuesto;
  final TextEditingController? observacionesController;
  final double retencion;

  @override
  Widget build(BuildContext context) {
    final mobile = AppBreakpoints.isMobile(context);
    final desktop = AppBreakpoints.isDesktop(context);

    if (!desktop) {
      // ── Móvil / tablet: diseño original ──
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
            if (mostrarImpuesto)
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

    // ── Escritorio: tarjeta RESUMEN Y CONFIRMACIÓN ──
    return AppCard(
      borderColor: AppColors.border,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(bottom: 8),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xFFF0F4F8), width: 2),
              ),
            ),
            child: const Text(
              'RESUMEN Y CONFIRMACIÓN',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: Color(0xFF2D3748),
              ),
            ),
          ),
          _fila('Subtotal', formatRd(subtotalSinImpuestos)),
          if (descuentoGlobal > 0)
            _fila('Descuento', formatRd(descuentoGlobal)),
          if (mostrarImpuesto)
            _fila('ITBIS / Impuesto', formatRd(montoImpuesto)),
          _fila('Retención', formatRd(retencion)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFE6F4F2),
              borderRadius: BorderRadius.circular(10),
              border: const Border(
                top: BorderSide(color: Color(0xFFCBD5E0), width: 1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A202C),
                  ),
                ),
                Text(
                  formatRd(totalCompra),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A202C),
                  ),
                ),
              ],
            ),
          ),
          if (observacionesController != null) ...[
            const SizedBox(height: 16),
            Text(
              'Observaciones de la compra',
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: observacionesController,
              maxLines: 3,
              style: AppTypography.bodySmall,
              decoration: InputDecoration(
                hintText: 'Notas opcionales…',
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                contentPadding: const EdgeInsets.all(12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _fila(String label, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
              fontSize: 14,
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
