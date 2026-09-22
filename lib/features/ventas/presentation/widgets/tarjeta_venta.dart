import 'package:flutter/material.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';

class TarjetaVenta extends StatelessWidget {
  const TarjetaVenta({
    super.key,
    required this.numero,
    required this.clienteNombre,
    required this.fecha,
    required this.total,
    this.numeroFactura,
    this.onTap,
  });

  final String numero;
  final String clienteNombre;
  final DateTime fecha;
  final double total;
  final String? numeroFactura;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final esPantallaPequena = MediaQuery.of(context).size.width < 600;
    final tamanoCuerpo = esPantallaPequena ? 13.0 : 14.0;
    final tamanoTotal = esPantallaPequena ? 15.0 : 16.0;
    final tamanoEtiqueta = esPantallaPequena ? 11.0 : 12.0;

    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: esPantallaPequena ? 12 : 14,
            vertical: esPantallaPequena ? 10 : 12,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      'N° $numero',
                      style: AppTypography.labelMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: esPantallaPequena ? 14 : 15,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  if (numeroFactura != null && numeroFactura!.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Factura: $numeroFactura',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.w600,
                          fontSize: tamanoEtiqueta,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(
                    Icons.person_outline,
                    size: 15,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      clienteNombre,
                      style: AppTypography.bodyMedium.copyWith(
                        fontSize: tamanoCuerpo,
                        color: AppColors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    '${fecha.day.toString().padLeft(2, '0')}/'
                    '${fecha.month.toString().padLeft(2, '0')}/'
                    '${fecha.year}',
                    style: AppTypography.bodySmall.copyWith(
                      fontSize: tamanoEtiqueta,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'RD\$ ${total.toStringAsFixed(2)}',
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: tamanoTotal,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
