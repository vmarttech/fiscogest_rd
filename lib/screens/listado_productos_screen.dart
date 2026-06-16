import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'formulario_producto_screen.dart'; // ✅ NOMBRE CORRECTO
import '../models/producto.dart';
import '../providers/producto_providers.dart';

class ListadoProductosScreen extends ConsumerStatefulWidget {
  const ListadoProductosScreen({super.key});

  @override
  ConsumerState<ListadoProductosScreen> createState() => _ListadoProductosScreenState();
}

class _ListadoProductosScreenState extends ConsumerState<ListadoProductosScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(productoNotifierProvider.notifier).cargarTodos());
  }

  @override
  Widget build(BuildContext context) {
    final listaProductos = ref.watch(productoNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Productos'),
        centerTitle: true,
        elevation: 4,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _irAFormulario(context),
        child: const Icon(Icons.add, size: 28),
      ),
      body: listaProductos.isEmpty
          ? const Center(child: Text('No hay productos registrados', style: TextStyle(fontSize: 16, color: Colors.grey)))
          : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: listaProductos.length,
              itemBuilder: (context, index) {
                final prod = listaProductos[index];
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    title: Text(prod.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                      'Código: ${prod.codigo} | Precio: RD\$ ${prod.precioVenta.toStringAsFixed(2)}\n'
                      'ITBIS: RD\$ ${prod.valorITBIS.toStringAsFixed(2)} | Existencia: ${prod.stockActual}',
                    ),
                    isThreeLine: true,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _irAFormulario(context, prod)),
                        IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _eliminar(prod.id!)),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _irAFormulario(BuildContext context, [Producto? producto]) async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => FormularioProductoScreen(producto: producto)),
    );
    if (resultado == true) {
      ref.read(productoNotifierProvider.notifier).cargarTodos();
    }
  }

  void _eliminar(int id) async {
    await ref.read(productoNotifierProvider.notifier).eliminar(id);
  }
}