import 'package:flutter/material.dart';
import 'package:fiscogest_rd/core/ui/app_spacing.dart';
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
                Text('RD\$ ${subtotalSinImpuestos.toStringAsFixed(2)}'),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Descuentos:'),
                Text('RD\$ ${descuentoGlobal.toStringAsFixed(2)}'),
              ],
            ),
            if (!modoSimplificado)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('ITBIS (18%):'),
                  Text('RD\$ ${montoImpuesto.toStringAsFixed(2)}'),
                ],
              ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('TOTAL COMPRA:', style: AppTypography.labelLarge),
                Text(
                  'RD\$ ${totalCompra.toStringAsFixed(2)}',
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
