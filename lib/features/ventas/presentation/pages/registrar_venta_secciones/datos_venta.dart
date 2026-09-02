import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/core/ui/app_card.dart';
import 'package:fiscogest_rd/core/ui/app_spacing.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/venta_providers.dart';

class DatosVenta extends ConsumerWidget {
  const DatosVenta({
    super.key,
    required this.alSeleccionarCliente,
    required this.alSeleccionarFormaPago,
  });

  final VoidCallback alSeleccionarCliente;
  final VoidCallback alSeleccionarFormaPago;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estadoLocal = ref.watch(registrarVentaProvider);
    return AppCard(
      padding: AppSpacing.allM,
      elevation: 2,
      child: Column(
        children: [
          Text(
            'Datos de la Venta',
            style: AppTypography.h4.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.m),
          _buildFilaDato(
            Icons.person,
            'Cliente',
            estadoLocal.clienteId != null
                ? 'Cliente ID ${estadoLocal.clienteId}'
                : 'Seleccionar',
            alSeleccionarCliente,
          ),
          const SizedBox(height: AppSpacing.m),
          _buildFilaDato(
            Icons.payment,
            'Forma de Pago',
            estadoLocal.tipoPago.isNotEmpty
                ? '${estadoLocal.tipoPago[0].toUpperCase()}${estadoLocal.tipoPago.substring(1)}${estadoLocal.esCredito ? ' (Crédito)' : ''}'
                : 'Seleccionar',
            alSeleccionarFormaPago,
          ),
          const Divider(height: AppSpacing.l),
          _buildFilaTotal('Subtotal', estadoLocal.subtotal),
          _buildFilaTotal('ITBIS (16%)', estadoLocal.itbis),
          const Divider(),
          _buildFilaTotal('TOTAL A PAGAR', estadoLocal.total, esTotal: true),
        ],
      ),
    );
  }

  Widget _buildFilaDato(
    IconData icono,
    String etiqueta,
    String valor,
    VoidCallback alPresionar,
  ) {
    return InkWell(
      onTap: alPresionar,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: AppSpacing.vS,
        child: Row(
          children: [
            Icon(icono, color: AppColors.textSecondary),
            const SizedBox(width: AppSpacing.m),
            Expanded(child: Text(etiqueta, style: AppTypography.bodyMedium)),
            Row(
              children: [
                Text(
                  valor,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilaTotal(
    String etiqueta,
    double monto, {
    bool esTotal = false,
  }) {
    return Padding(
      padding: AppSpacing.vS,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            etiqueta,
            style: esTotal
                ? AppTypography.h4.copyWith(fontWeight: FontWeight.bold)
                : AppTypography.bodyMedium,
          ),
          Text(
            'RD\$ ${monto.toStringAsFixed(2)}',
            style: esTotal
                ? AppTypography.h3.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.success,
                  )
                : AppTypography.bodyMedium,
          ),
        ],
      ),
    );
  }
}
