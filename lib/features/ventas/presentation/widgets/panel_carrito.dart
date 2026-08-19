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
                  child: const Icon(Icons.shopping_cart_outlined,
                      size: 20, color: Color(0xFF1565C0)),
                ),
                const SizedBox(width: 11),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Carrito de venta',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF252A30))),
                    Text('Productos agregados',
                        style: TextStyle(fontSize: 12, color: Color(0xFF868E96))),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (estado.detalles.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: Text('No hay productos agregados',
                    style: TextStyle(fontSize: 14, color: Color(0xFF868E96)))),
              )
            else
              ...List.generate(estado.detalles.length, (i) =>
                ItemCarrito(linea: estado.detalles[i], indice: i),
              ),
            const SizedBox(height: 16),
            const Divider(height: 1, color: Color(0xFFE3E6EA)),
            const SizedBox(height: 12),
            _buildFilaTotal('Subtotal', estado.subtotal),
            const SizedBox(height: 6),
            _buildFilaTotal('ITBIS (16%)', estado.itbis),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.only(top: 10),
              decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFFE3E6EA)))),
              child: _buildFilaTotal('TOTAL', estado.total, esResaltado: true),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilaTotal(String etiqueta, double valor, {bool esResaltado = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(etiqueta,
            style: TextStyle(fontSize: esResaltado ? 15 : 13,
                fontWeight: esResaltado ? FontWeight.w700 : FontWeight.w500,
                color: esResaltado ? const Color(0xFF20242A) : const Color(0xFF495057))),
        Text('RD\$ ${valor.toStringAsFixed(2)}',
            style: TextStyle(fontSize: esResaltado ? 17 : 14,
                fontWeight: esResaltado ? FontWeight.w800 : FontWeight.w600,
                color: esResaltado ? const Color(0xFF1565C0) : const Color(0xFF212529))),
      ],
    );
  }
}
