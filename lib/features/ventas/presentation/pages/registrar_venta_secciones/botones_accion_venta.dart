import 'package:flutter/material.dart';
import 'package:fiscogest_rd/core/ui/app_button.dart';
import 'package:fiscogest_rd/core/ui/app_spacing.dart';

enum ModoOperacionVenta { venta, cotizacion, apartado }

class BotonesAccionVenta extends StatelessWidget {
  const BotonesAccionVenta({
    super.key,
    required this.cargando,
    required this.alLimpiar,
    required this.alGuardar,
    this.modo = ModoOperacionVenta.venta,
  });

  final bool cargando;
  final VoidCallback alLimpiar;
  final VoidCallback alGuardar;
  final ModoOperacionVenta modo;

  String get _textoBotonPrincipal {
    return switch (modo) {
      ModoOperacionVenta.cotizacion => 'GENERAR COTIZACIÓN',
      ModoOperacionVenta.venta => 'COBRAR',
      ModoOperacionVenta.apartado => 'RESERVAR',
    };
  }

  IconData get _iconoBotonPrincipal {
    return switch (modo) {
      ModoOperacionVenta.cotizacion => Icons.description,
      ModoOperacionVenta.venta => Icons.payment,
      ModoOperacionVenta.apartado => Icons.bookmark_added,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: alLimpiar,
            icon: const Icon(Icons.refresh),
            label: const Text('Limpiar'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.m),
        Expanded(
          child: AppButton(
            text: cargando ? 'Procesando...' : _textoBotonPrincipal,
            onPressed: cargando ? null : alGuardar,
            isLoading: cargando,
            icon: _iconoBotonPrincipal,
          ),
        ),
      ],
    );
  }
}
