import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/features/inventario/domain/entities/producto.dart';
import 'package:fiscogest_rd/features/inventario/presentation/providers/producto_providers.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/venta.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/venta_providers.dart';

class PanelProductos extends ConsumerStatefulWidget {
  const PanelProductos({super.key});

  @override
  ConsumerState<PanelProductos> createState() => _PanelProductosState();
}

class _PanelProductosState extends ConsumerState<PanelProductos> {
  final TextEditingController _buscador = TextEditingController();

  @override
  void dispose() {
    _buscador.dispose();
    super.dispose();
  }

  void _agregarProductoSeleccionado(Producto producto) {
    final precio = producto.precioVenta.toDouble();
    const cantidad = 1.0;
    final linea = DetalleVenta(
      productoId: producto.id ?? 0,
      nombreProducto: producto.nombre,
      cantidad: cantidad,
      precioUnitario: precio,
      subtotalLinea: cantidad * precio,
    );
    ref.read(registrarVentaProvider.notifier).agregarProducto(linea);
    _buscador.clear();
  }

  @override
  Widget build(BuildContext context) {
    final productosAsync = ref.watch(productoControllerProvider);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE1E5EA)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Productos', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            TextField(
              controller: _buscador,
              decoration: InputDecoration(
                hintText: 'Buscar producto...',
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(11), borderSide: BorderSide.none),
                prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF68717D)),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            productosAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (productos) {
                final filtro = productos.where((p) {
                  final termino = _buscador.text.toLowerCase();
                  return termino.isEmpty || p.nombre.toLowerCase().contains(termino);
                }).toList();
                return filtro.isEmpty
                    ? const Padding(padding: EdgeInsets.all(32), child: Center(child: Text('No se encontraron productos')))
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: filtro.length,
                        itemBuilder: (_, i) {
                          final p = filtro[i];
                          return ListTile(
                            title: Text(p.nombre),
                            subtitle: Text('RD\$ ${p.precioVenta.toStringAsFixed(2)}'),
                            onTap: () => _agregarProductoSeleccionado(p),
                          );
                        },
                      );
              },
            ),
          ],
        ),
      ),
    );
  }
}
