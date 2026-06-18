import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/producto_providers.dart';
import '../models/producto.dart';
import 'formulario_producto_screen.dart';

class ProductosPorRegimenScreen extends ConsumerWidget {
  final String nombreRegimen;
  final double tasa;

  const ProductosPorRegimenScreen({
    super.key,
    required this.nombreRegimen,
    required this.tasa,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todos = ref.watch(productoNotifierProvider);

    // ✅ CORRECCIÓN: QUITAMOS EL ?. porque el valor NO es nulo
    final listaFiltrada = todos
        .where((p) => p.regimenImpuesto.trim() == nombreRegimen.trim())
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(nombreRegimen),
        centerTitle: true,
        backgroundColor: Colors.blueGrey[700],
      ),
      body: listaFiltrada.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inventory_2_outlined, size: 60, color: Colors.grey),
                  SizedBox(height: 10),
                  Text(
                    'No hay productos registrados en este régimen',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: listaFiltrada.length,
              itemBuilder: (context, index) {
                final producto = listaFiltrada[index];

                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    title: Text(
                      producto.nombre,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'Código: ${producto.codigo} | ${producto.unidadMedida} \nStock: ${producto.stockActual} | Precio: RD\$ ${producto.precioVenta.toStringAsFixed(2)}',
                    ),
                    isThreeLine: true,
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: producto.aplicaImpuesto ? Colors.red[100] : Colors.green[100],
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        '${tasa.toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: producto.aplicaImpuesto ? Colors.red[800] : Colors.green[800],
                        ),
                      ),
                    ),
                    onTap: () => _editarProducto(context, producto, ref),
                  ),
                );
              },
            ),
    );
  }

  void _editarProducto(BuildContext context, Producto producto, WidgetRef ref) async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FormularioProductoScreen(producto: producto),
      ),
    );
    // ✅ LLAMADA CORRECTA A MÉTODO PÚBLICO
    if (resultado == true) {
      ref.read(productoNotifierProvider.notifier).cargarDatos();
    }
  }
}