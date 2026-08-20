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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        title: Text(detalle.nombreProducto),
        subtitle: Text('Cant: ${detalle.cantidad} • RD\$ ${detalle.subtotalLinea.toStringAsFixed(2)}'),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          onPressed: alEliminar,
        ),
      ),
    );
  }
}
