import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/producto.dart'; // ✅ IMPORT OBLIGATORIO
import '../providers/producto_providers.dart'; // ✅ RUTA CORRECTA AL PROVIDER
import 'formulario_producto_screen.dart';

class ListadoProductosScreen extends ConsumerStatefulWidget {
  const ListadoProductosScreen({super.key});

  @override
  ConsumerState<ListadoProductosScreen> createState() => _ListadoProductosScreenState();
}

class _ListadoProductosScreenState extends ConsumerState<ListadoProductosScreen> {
  @override
  Widget build(BuildContext context) {
    // 🔹 OBTENEMOS TODOS LOS PRODUCTOS DESDE EL ESTADO
    final listaProductos = ref.watch(productoNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Productos'),
        centerTitle: true,
        backgroundColor: Colors.blueGrey[800],
      ),

      // ✅ BOTÓN FLOTANTE DE AGREGAR - AHORA SIEMPRE VISIBLE
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Nuevo Producto', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green[700],
        elevation: 6,
        onPressed: () => _irAFormulario(context), // ✅ FUNCIÓN PARA ABRIR FORMULARIO
      ),

      body: listaProductos.isEmpty
          ? const Center(
              child: Text(
                'No hay productos registrados',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: listaProductos.length,
              itemBuilder: (context, i) {
                final prod = listaProductos[i];
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    title: Text(prod.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                      'Código: ${prod.codigo} | Stock: ${prod.stockActual} ${prod.unidadMedida}\nPrecio: RD\$ ${prod.precioVenta.toStringAsFixed(2)}',
                    ),
                    isThreeLine: true,
                    trailing: const Icon(Icons.edit, color: Colors.blueGrey),
                    // ✅ AL TOCAR, ABRE EN MODO EDICIÓN
                    onTap: () => _irAFormulario(context, producto: prod),
                  ),
                );
              },
            ),
    );
  }

  // ✅ FUNCIÓN DE NAVEGACIÓN AL FORMULARIO (CREAR O EDITAR)
  void _irAFormulario(BuildContext context, {Producto? producto}) async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FormularioProductoScreen(producto: producto),
      ),
    );
    // ✅ CORRECCIÓN CLAVE: USAMOS MÉTODO PÚBLICO `cargarDatos()`
    // ❌ ANTES: ._cargarDatos() (privado, causaba error)
    // ✅ AHORA: .cargarDatos() (público, definido en el Notifier)
    if (resultado == true) {
      ref.read(productoNotifierProvider.notifier).cargarDatos();
    }
  }
}