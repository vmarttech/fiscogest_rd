import 'package:flutter/material.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/venta.dart';

class ItemCarrito extends StatelessWidget {

  const ItemCarrito({
    super.key,
    required this.detalle,
    required this.alEliminar,
  });
  final DetalleVenta detalle;
  final VoidCallback alEliminar;

  @override
  Widget build(BuildContext context) {
    final tieneOferta = detalle.ofertaId != null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        title: Row(
          children: [
            Text(detalle.nombreProducto),
            if (tieneOferta)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'OFERTA',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade700,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Cant: ${detalle.cantidad} • RD\$ ${detalle.subtotalLinea.toStringAsFixed(2)}'),
            if (tieneOferta && detalle.precioOriginal != null)
              Text(
                'Precio original: RD\$ ${detalle.precioOriginal!.toStringAsFixed(2)} → Oferta: RD\$ ${detalle.precioUnitario.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.orange.shade700,
                ),
              ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          onPressed: alEliminar,
        ),
      ),
    );
  }
}
