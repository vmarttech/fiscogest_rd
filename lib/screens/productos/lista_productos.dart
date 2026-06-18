import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/producto_notifier.dart';
import 'formulario_producto.dart';

class ListaProductosScreen extends ConsumerWidget {
  const ListaProductosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lista = ref.watch(productoNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Productos')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const FormularioProductoScreen()),
        ),
        child: const Icon(Icons.add),
      ),
      body: lista.isEmpty
          ? const Center(child: Text('No hay productos registrados'))
          : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: lista.length,
              itemBuilder: (_, i) {
                final p = lista[i];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: ListTile(
                    title: Text('${p.codigo} - ${p.nombre}'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Costo final: ${p.costoRealConImpuesto.toStringAsFixed(2)} RD\$'),
                        Text('Venta: ${p.precioVenta.toStringAsFixed(2)} RD\$'),
                        Text('Ganancia: ${p.porcentajeGananciaReal.toStringAsFixed(1)}%'),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => FormularioProductoScreen(producto: p)),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            final confirmar = await showDialog(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text('Eliminar'),
                                content: const Text('¿Está seguro?'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
                                  TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sí')),
                                ],
                              ),
                            );
                            if (confirmar == true) {
                              await ref.read(productoNotifierProvider.notifier).borrar(p.id!);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}