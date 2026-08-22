import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/descuento.dart';
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
              child: const SelectorDescuento(),
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
    final controladorDescuento = TextEditingController(
      text: estado.montoDescuento > 0 ? estado.montoDescuento.toStringAsFixed(2) : '',
    );
    bool esPorcentaje = false;

    void aplicarValorDescuento(String valorTexto, bool enPorcentaje) {
      final double valor = double.tryParse(valorTexto) ?? 0.0;
      final double totalSinDescuento = estado.subtotal + estado.itbis;
      final double montoFinal = enPorcentaje
          ? (totalSinDescuento * valor / 100).clamp(0.0, totalSinDescuento)
          : valor;
      final DateTime hoy = DateTime.now();
      final descuento = Descuento(
        id: 0,
        nombre: enPorcentaje ? 'Manual %' : 'Manual',
        tipo: 'monto',
        valor: montoFinal,
        aplicaA: 'general',
        vigenciaDesde: hoy,
        vigenciaHasta: hoy.add(const Duration(days: 365)),
        estado: 'activo',
      );
      ref.read(registrarVentaProvider.notifier).aplicarDescuento(descuento);
    }

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
            Align(
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 180,
                    child: TextField(
                      controller: controladorDescuento,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Descuento RD\$',
                        hintText: '0.00',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      onSubmitted: (String valor) => aplicarValorDescuento(valor, false),
                    ),
                  ),
                  const SizedBox(width: 8),
                  StatefulBuilder(
                    builder: (ctx, setEstado) => ElevatedButton(
                      onPressed: () {
                        setEstado(() => esPorcentaje = !esPorcentaje);
                        aplicarValorDescuento(controladorDescuento.text, esPorcentaje);
                      },
                      child: Text(esPorcentaje ? 'RD\$' : '%'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => _abrirSelectorDescuento(context),
                child: const Text('Seleccionar descuento de lista'),
              ),
            ),
            if (estado.montoDescuento > 0) ...[
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Descuento aplicado: - RD\$ ${estado.montoDescuento.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 8),
            _buildFilaTotal('Subtotal', estado.subtotal),
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
