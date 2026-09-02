import 'package:flutter/material.dart';
import 'package:fiscogest_rd/core/ui/app_button.dart';
import 'package:fiscogest_rd/core/ui/app_spacing.dart';

class BotonesAccionVenta extends StatelessWidget {
  const BotonesAccionVenta({
    super.key,
    required this.cargando,
    required this.alLimpiar,
    required this.alGuardar,
  });

  final bool cargando;
  final VoidCallback alLimpiar;
  final VoidCallback alGuardar;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: alLimpiar,
            icon: const Icon(Icons.refresh),
            label: const Text('Limpiar Venta'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.m),
        Expanded(
          child: AppButton(
            text: cargando ? 'Guardando...' : 'Registrar Venta',
            onPressed: cargando ? null : alGuardar,
            isLoading: cargando,
            icon: Icons.save,
          ),
        ),
      ],
    );
  }
}
