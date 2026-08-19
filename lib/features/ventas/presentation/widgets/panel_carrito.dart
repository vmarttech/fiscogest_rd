import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/venta_providers.dart';
import 'package:fiscogest_rd/features/ventas/presentation/widgets/item_carrito.dart';

class PanelCarrito extends ConsumerWidget {
  const PanelCarrito({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estado = ref.watch(registrarVentaProvider);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE1E5EA))),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Carrito', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            if (estado.detalles.isEmpty)
              const Padding(padding: EdgeInsets.symmetric(vertical: 40), child: Center(child: Text('No hay productos agregados', style: TextStyle(color: Color(0xFF868E96)))))
            else
              ...List.generate(estado.detalles.length, (i) => ItemCarrito(linea: estado.detalles[i], indice: i)),
            const SizedBox(height: 16),
            const Divider(height: 1, color: Color(0xFFE3E6EA)),
            const SizedBox(height: 12),
            _fila('Subtotal', estado.subtotal),
            const SizedBox(height: 6),
            _fila('ITBIS (16%)', estado.itbis),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.only(top: 10),
              decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFFE3E6EA)))),
              child: Row(children: [const Expanded(child: Text('TOTAL', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800))), Text('RD\$ ${estado.total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1565C0)))]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fila(String etiqueta, double valor) => Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(etiqueta), Text('RD\$ ${valor.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w600))]);
}
