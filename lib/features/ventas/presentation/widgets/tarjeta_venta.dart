import 'package:flutter/material.dart';

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
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Venta Nº $numero', style: const TextStyle(fontWeight: FontWeight.bold)),
                  if (numeroFactura != null && numeroFactura!.isNotEmpty)
                    Text('Factura: $numeroFactura', style: const TextStyle(fontSize: 13)),
                ],
              ),
              const SizedBox(height: 2),
              Text('Cliente: $clienteNombre', style: const TextStyle(fontSize: 13)),
              Text('Fecha: ${fecha.day}/${fecha.month}/${fecha.year}', style: const TextStyle(fontSize: 13)),
              const SizedBox(height: 4),
              Text('Total: RD\$ ${total.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }
}
