import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/existencia_provider.dart';
// ✅ ELIMINADO: import '../models/existencia.dart'; (No se usaba directamente)
import 'formulario_movimiento.dart';

class ListadoInventarioScreen extends ConsumerStatefulWidget {
  const ListadoInventarioScreen({super.key});

  @override
  ConsumerState<ListadoInventarioScreen> createState() => _ListadoInventarioScreenState();
}

class _ListadoInventarioScreenState extends ConsumerState<ListadoInventarioScreen> {
  String _terminoBusqueda = '';

  @override
  Widget build(BuildContext context) {
    final inventarioAsync = ref.watch(todosLosInventariosProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Control de Inventario'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_chart),
            tooltip: 'Nuevo Movimiento',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FormularioMovimientoScreen()),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // 🔍 Barra de Búsqueda
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Buscar por código o nombre...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (valor) {
                setState(() {
                  _terminoBusqueda = valor.toLowerCase();
                });
              },
            ),
          ),

          // 📊 Resumen rápido
          inventarioAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (error, __) => const SizedBox.shrink(),
            data: (lista) {
              final totalArticulos = lista.length;
              final bajosStock = lista.where((item) => item.estaBajoMinimo).length;

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Colors.blue.shade50,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total: $totalArticulos artículos'),
                    Text(
                      'Bajo stock: $bajosStock',
                      style: TextStyle(
                        color: bajosStock > 0 ? Colors.red : Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 8),

          // 📋 Lista de Inventario
          Expanded(
            child: inventarioAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, pila) => Center(child: Text('Error: $error')),
              data: (listaCompleta) {
                // Filtrado
                final listaFiltrada = _terminoBusqueda.isEmpty
                    ? listaCompleta
                    : listaCompleta.where((item) =>
                        item.codigoProducto.toLowerCase().contains(_terminoBusqueda) ||
                        item.nombreProducto.toLowerCase().contains(_terminoBusqueda)
                      ).toList();

                if (listaFiltrada.isEmpty) {
                  return const Center(child: Text('No hay registros de inventario'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: listaFiltrada.length,
                  itemBuilder: (context, indice) {
                    final item = listaFiltrada[indice];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      elevation: 2,
                      child: ListTile(
                        leading: Icon(
                          item.estaBajoMinimo ? Icons.warning_amber : Icons.inventory_2,
                          color: item.estaBajoMinimo ? Colors.orange : Colors.blueGrey,
                          size: 32,
                        ),
                        title: Text('${item.codigoProducto} - ${item.nombreProducto}'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Ubicación: ${item.ubicacion}'),
                            Row(
                              children: [
                                Text('Disponible: ${item.cantidadDisponible.toStringAsFixed(2)}'),
                                const SizedBox(width: 16),
                                Text('Reservado: ${item.cantidadReservada.toStringAsFixed(2)}'),
                              ],
                            ),
                            Text(
                              'Stock Mín: ${item.cantidadMinima.toStringAsFixed(2)} | Máx: ${item.cantidadMaxima.toStringAsFixed(2)}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              item.cantidadReal.toStringAsFixed(2),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: item.estaBajoMinimo ? Colors.red : Colors.green.shade700,
                              ),
                            ),
                            const Text('Real', style: TextStyle(fontSize: 11)),
                          ],
                        ),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => FormularioMovimientoScreen(existencia: item),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}