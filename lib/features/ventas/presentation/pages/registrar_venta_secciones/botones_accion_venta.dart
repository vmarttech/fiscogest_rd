import 'package:flutter/material.dart';

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
            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: cargando ? null : alGuardar,
            icon: cargando
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                : const Icon(Icons.save),
            label: Text(cargando ? 'Guardando...' : 'Registrar Venta'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ],
    );
  }
}
