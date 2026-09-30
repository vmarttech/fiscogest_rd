import 'package:flutter/material.dart';
import 'package:fiscogest_rd/core/ui/app_spacing.dart';
import 'package:fiscogest_rd/core/ui/app_formatters.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';

class TotalesCompraWidget extends StatelessWidget {
  const TotalesCompraWidget({
    super.key,
    required this.subtotalSinImpuestos,
    required this.descuentoGlobal,
    required this.montoImpuesto,
    required this.totalCompra,
    this.modoSimplificado = false,
  });
  final double subtotalSinImpuestos;
  final double descuentoGlobal;
  final double montoImpuesto;
  final double totalCompra;
  final bool modoSimplificado;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.green.shade50,
      child: Padding(
        padding: AppSpacing.allM,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Subtotal:'),
                Text(formatRd(subtotalSinImpuestos)),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Descuentos:'),
                Text(formatRd(descuentoGlobal)),
              ],
            ),
            if (!modoSimplificado)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('ITBIS (18%):'),
                  Text(formatRd(montoImpuesto)),
                ],
              ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('TOTAL COMPRA:', style: AppTypography.labelLarge),
                Text(
                  formatRd(totalCompra),
                  style: AppTypography.labelLarge.copyWith(
                    color: Colors.green.shade700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
