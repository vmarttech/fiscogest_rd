import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/venta_providers.dart';
import 'package:fiscogest_rd/features/ventas/presentation/widgets/item_carrito.dart';

class PanelCarrito extends ConsumerWidget {
  const PanelCarrito({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estado = ref.watch(registrarVentaProvider);
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Carrito', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('${estado.detalles.length} productos'),
              ],
            ),
            const Divider(),
            if (estado.detalles.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: Text('Busque y agregue productos arriba')),
              )
            else
              ...estado.detalles.map((detalle) => ItemCarrito(
                    detalle: detalle,
                    alEliminar: () => ref
                        .read(registrarVentaProvider.notifier)
                        .quitarProducto(estado.detalles.indexOf(detalle)),
                  )),
            const Divider(height: 24),
            _buildFilaTotal('Subtotal', estado.subtotal),
            _buildFilaTotal('ITBIS (16%)', estado.itbis),
            const Divider(),
            _buildFilaTotal('TOTAL A PAGAR', estado.total, esTotal: true),
          ],
        ),
      ),
    );
  }

  Widget _buildFilaTotal(String etiqueta, double monto, {bool esTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(etiqueta,
              style: TextStyle(fontWeight: esTotal ? FontWeight.bold : FontWeight.normal, fontSize: esTotal ? 16 : 14)),
          Text('RD\$ ${monto.toStringAsFixed(2)}',
              style: TextStyle(
                  fontWeight: esTotal ? FontWeight.bold : FontWeight.normal,
                  fontSize: esTotal ? 18 : 14,
                  color: esTotal ? Colors.green : Colors.black87)),
        ],
      ),
    );
  }
}
