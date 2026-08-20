import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/venta_providers.dart';
import 'package:fiscogest_rd/features/ventas/presentation/widgets/item_carrito.dart';
import 'package:fiscogest_rd/features/ventas/presentation/widgets/selector_descuento.dart';

class PanelCarrito extends ConsumerWidget {
  const PanelCarrito({super.key});

  void _abrirSelectorDescuento(BuildContext context) {
    showDialog<dynamic>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Seleccionar Descuento'),
        contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        content: SizedBox(
          width: 500,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 450),
            child: const SingleChildScrollView(
              child: SelectorDescuento(),
            ),
          ),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estado = ref.watch(registrarVentaProvider);
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // === TITULO DEL CARRITO ===
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Carrito',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  '${estado.detalles.length} productos',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // === LISTA DE PRODUCTOS ===
            if (estado.detalles.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: Text(
                    'Busque y agregue productos arriba',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              Flexible(
                fit: FlexFit.loose,
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: estado.detalles.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (ctx, i) {
                    final detalle = estado.detalles[i];
                    return ItemCarrito(
                      detalle: detalle,
                      alEliminar: () => ref
                          .read(registrarVentaProvider.notifier)
                          .quitarProducto(i),
                    );
                  },
                ),
              ),

            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 8),

            // === BOTÓN APLICAR DESCUENTO ===
            InkWell(
              onTap: () => _abrirSelectorDescuento(context),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.local_offer, color: Colors.blueGrey, size: 20),
                        const SizedBox(width: 12),
                        Text(
                          estado.descuentoNombre != null
                              ? 'Descuento: ${estado.descuentoNombre}'
                              : 'Aplicar Descuento',
                          style: TextStyle(
                            fontWeight: estado.descuentoNombre != null
                                ? FontWeight.w600
                                : FontWeight.normal,
                            color: estado.descuentoNombre != null
                                ? Colors.green.shade700
                                : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        if (estado.montoDescuento > 0)
                          Text(
                            '- RD\$ ${estado.montoDescuento.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 8),

            // === DESGLOSE DE TOTALES ===
            _buildFilaTotal('Subtotal', estado.subtotal),

            // === SOLO APARECE SI HAY DESCUENTO ===
            if (estado.montoDescuento > 0) ...[
              const SizedBox(height: 4),
              _buildFilaTotal('Descuento', estado.montoDescuento, esDescuento: true),
              _buildFilaTotal('Base Gravable', estado.subtotal - estado.montoDescuento),
            ],

            const SizedBox(height: 4),
            _buildFilaTotal('ITBIS', estado.itbis),

            const SizedBox(height: 12),
            const Divider(height: 1, thickness: 1.2),
            const SizedBox(height: 8),

            // === TOTAL FINAL ===
            _buildFilaTotal('TOTAL A PAGAR', estado.total, esTotal: true),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildFilaTotal(String etiqueta, double monto, {bool esTotal = false, bool esDescuento = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            etiqueta,
            style: TextStyle(
              fontWeight: esTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: esTotal ? 16 : 14,
              color: esTotal ? Colors.green.shade800 : const Color(0xFF424242),
            ),
          ),
          Text(
            '${esDescuento ? '- ' : ''}RD\$ ${monto.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: esTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: esTotal ? 18 : 14,
              color: esTotal
                  ? Colors.green.shade700
                  : esDescuento
                      ? Colors.green.shade700
                      : const Color(0xFF212121),
            ),
          ),
        ],
      ),
    );
  }
}
