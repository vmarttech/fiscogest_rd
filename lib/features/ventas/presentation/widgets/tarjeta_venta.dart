import 'package:flutter/material.dart';

class TarjetaVenta extends StatelessWidget {

  const TarjetaVenta({
    super.key,
    required this.numero,
    required this.clienteNombre,
    required this.fecha,
    required this.total,
    this.onTap,
  });
  final String numero;
  final String clienteNombre;
  final DateTime fecha;
  final double total;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Venta Nº $numero', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('Cliente: $clienteNombre'),
              Text('Fecha: ${fecha.day}/${fecha.month}/${fecha.year}'),
              const SizedBox(height: 8),
              Text('Total: RD\$ ${total.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}
