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

  void _agregarProducto() {
    final linea = const DetalleVenta(
      productoId: 0,
      nombreProducto: 'Producto desde búsqueda',
      cantidad: 1,
      precioUnitario: 0.0,
      subtotalLinea: 0.0,
    );
    ref.read(registrarVentaProvider.notifier).agregarProducto(linea);
    _buscador.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE1E5EA))),
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
                suffixIcon: ElevatedButton.icon(icon: const Icon(Icons.add, size: 18), label: const Text('Agregar'), onPressed: _agregarProducto),
              ),
              onSubmitted: (_) => _agregarProducto(),
            ),
          ],
        ),
      ),
    );
  }
}
