import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  void _agregarProductoPrueba() {
    final linea = const DetalleVenta(
      productoId: 1,
      nombreProducto: 'Producto de prueba',
      cantidad: 1,
      precioUnitario: 100.00,
      subtotalLinea: 100.00,
    );
    ref.read(registrarVentaProvider.notifier).agregarProducto(linea);
    _buscador.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE1E5EA)),
        boxShadow: const [
          BoxShadow(color: Color(0x08000000), blurRadius: 14, offset: Offset(0, 4)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF2FC),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.inventory_2_outlined,
                      size: 20, color: Color(0xFF1565C0)),
                ),
                const SizedBox(width: 11),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Productos',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF252A30))),
                    Text('Busca y agrega artículos',
                        style: TextStyle(fontSize: 12, color: Color(0xFF868E96))),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _buscador,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Buscar por nombre, código o EAN...',
                hintStyle: const TextStyle(fontSize: 14, color: Color(0xFFADB5BD)),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(11), borderSide: BorderSide.none),
                prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF68717D)),
                suffixIcon: ElevatedButton.icon(
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Agregar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1565C0),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: _agregarProductoPrueba,
                ),
              ),
              onSubmitted: (_) => _agregarProductoPrueba(),
            ),
          ],
        ),
      ),
    );
  }
}
