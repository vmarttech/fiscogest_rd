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
        content: const SingleChildScrollView(
          child: SizedBox(
            width: double.maxFinite,
            child: SelectorDescuento(),
          ),
        ),
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Carrito', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('${estado.detalles.length} productos'),
              ],
            ),
            const Divider(),
            if (estado.detalles.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: Text('Busque y agregue productos arriba')),
              )
            else
              ...estado.detalles.map((detalle) => ItemCarrito(
                    detalle: detalle,
                    alEliminar: () => ref
                        .read(registrarVentaProvider.notifier)
                        .quitarProducto(estado.detalles.indexOf(detalle)),
                  )),
            const Divider(height: 24),
            InkWell(
              onTap: () => _abrirSelectorDescuento(context),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.local_offer, color: Colors.blueGrey),
                        const SizedBox(width: 12),
                        Text(
                          estado.descuentoNombre != null
                              ? 'Descuento: ${estado.descuentoNombre}'
                              : 'Aplicar Descuento',
                          style: TextStyle(
                            fontWeight: estado.descuentoNombre != null
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: estado.descuentoNombre != null
                                ? Colors.green
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
                            style: const TextStyle(
                              color: Colors.green,
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
            const SizedBox(height: 8),
            _buildFilaTotal('Subtotal', estado.subtotal),
            if (estado.montoDescuento > 0)
              _buildFilaTotal(
                'Descuento',
                estado.montoDescuento,
                esDescuento: true,
              ),
            if (estado.montoDescuento > 0)
              _buildFilaTotal('Base Gravable', estado.subtotal - estado.montoDescuento),
            _buildFilaTotal('ITBIS (16%)', estado.itbis),
            const Divider(),
            _buildFilaTotal('TOTAL A PAGAR', estado.total, esTotal: true),
          ],
        ),
      ),
    );
  }

  Widget _buildFilaTotal(String etiqueta, double monto,
      {bool esTotal = false, bool esDescuento = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            etiqueta,
            style: TextStyle(
              fontWeight: esTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: esTotal ? 16 : 14,
            ),
          ),
          Text(
            '${esDescuento ? '- ' : ''}RD\$ ${monto.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: esTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: esTotal ? 18 : 14,
              color: esTotal
                  ? Colors.green
                  : esDescuento
                      ? Colors.green
                      : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
