import 'package:flutter/material.dart';
import 'package:fiscogest_rd/core/ui/app_button.dart';
import 'package:fiscogest_rd/core/ui/app_layout.dart';

class BotonesAccionWidget extends StatelessWidget {
  const BotonesAccionWidget({
    super.key,
    required this.onGuardarBorrador,
    required this.onRegistrarCompra,
  });
  final VoidCallback onGuardarBorrador;
  final VoidCallback onRegistrarCompra;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: onGuardarBorrador,
            child: const Text('Guardar Borrador'),
          ),
        ),
        AppLayout.hM,
        Expanded(
          flex: 2,
          child: AppButton(
            text: 'Registrar Compra',
            onPressed: onRegistrarCompra,
          ),
        ),
      ],
    );
  }
}
