import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/venta_providers.dart';

class CarritoVenta extends ConsumerWidget {
  const CarritoVenta({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estadoLocal = ref.watch(registrarVentaProvider);
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
                Text('${estadoLocal.detalles.length} productos'),
              ],
            ),
            const Divider(),
            if (estadoLocal.detalles.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: Text('Busque y agregue productos arriba')),
              )
            else
              ...estadoLocal.detalles.map((detalle) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  title: Text(detalle.nombreProducto),
                  subtitle: Text('Cant: ${detalle.cantidad} • RD\$ ${detalle.subtotalLinea.toStringAsFixed(2)}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => ref
                        .read(registrarVentaProvider.notifier)
                        .quitarProducto(estadoLocal.detalles.indexOf(detalle)),
                  ),
                ),
              )),
          ],
        ),
      ),
    );
  }
}
