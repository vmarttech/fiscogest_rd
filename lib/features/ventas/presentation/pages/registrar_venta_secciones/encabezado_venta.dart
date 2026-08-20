import 'package:flutter/material.dart';

class EncabezadoVenta extends StatelessWidget {
  const EncabezadoVenta({super.key, required this.numeroVenta});
  final String numeroVenta;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Nueva Venta',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(
              'Nº $numeroVenta',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.blueGrey),
            ),
          ],
        ),
      ),
    );
  }
}
