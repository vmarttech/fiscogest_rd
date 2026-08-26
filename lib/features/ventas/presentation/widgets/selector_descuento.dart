import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/features/comercial/domain/entities/descuento.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/venta_providers.dart';
class SelectorDescuento extends ConsumerWidget {
  const SelectorDescuento({super.key, this.esParaCotizacion = false});
  final bool esParaCotizacion;
  String _formatearValor(Descuento descuento) {
    if (descuento.esPorcentaje) {
      return '${descuento.valor.toStringAsFixed(0)}%';
    }
    return 'RD\$ ${descuento.valor.toStringAsFixed(2)}';
  }
  String _formatearTipo(TipoDescuento tipo) {
    switch (tipo) {
      case TipoDescuento.porProducto:
        return 'Por producto';
      case TipoDescuento.porFactura:
        return 'Por total de venta';
    }
  }
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final descuentosAsync = ref.watch(descuentosActivosProvider);
    return descuentosAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (Object error, StackTrace stack) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 8),
            Text('Error al cargar descuentos: $error'),
          ],
        ),
      ),
      data: (List<Descuento> descuentos) {
        final estadoVenta = ref.watch(registrarVentaProvider);
        final estadoCot = ref.watch(ventaBorradorProvider);
        final int? descuentoId = esParaCotizacion
            ? estadoCot.descuentoId
            : estadoVenta.descuentoId;
        final String? descuentoNombre = esParaCotizacion
            ? estadoCot.descuentoNombre
            : estadoVenta.descuentoNombre;
        final double montoDescuento = esParaCotizacion
            ? estadoCot.descuento
            : estadoVenta.montoDescuento;
        final descuentosActivos = descuentos.where((d) => d.activo).toList();
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (descuentoId != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Descuento aplicado: $descuentoNombre',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        Text(
                          'Monto: RD\$ ${montoDescuento.toStringAsFixed(2)}',
                          style: const TextStyle(color: Colors.green),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: () {
                        if (esParaCotizacion) {
                          ref.read(ventaBorradorProvider.notifier).quitarDescuento();
                        } else {
                          ref.read(registrarVentaProvider.notifier).quitarDescuento();
                        }
                      },
                      child: const Text('Quitar'),
                    ),
                  ],
                ),
              ),
            if (descuentosActivos.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(
                  child: Text('No hay descuentos vigentes disponibles'),
                ),
              )
            else
              ...descuentosActivos.map((descuento) {
                final int? descuentoIdInt = int.tryParse(descuento.id);
                final bool seleccionado = descuentoId == descuentoIdInt;
                return Card(
                  elevation: seleccionado ? 4 : 1,
                  color: seleccionado ? Colors.blue.shade50 : null,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(
                      color: seleccionado ? Colors.blue : Colors.grey.shade200,
                      width: seleccionado ? 2 : 1,
                    ),
                  ),
                  child: ListTile(
                    title: Text(
                      descuento.motivo,
                      style: TextStyle(
                        fontWeight: seleccionado ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    subtitle: Text(_formatearTipo(descuento.tipo)),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _formatearValor(descuento),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          _formatearTipo(descuento.tipo),
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                    onTap: () {
                      final double valor = descuento.valor;
                      final int? id = int.tryParse(descuento.id);
                      final String nombre = descuento.motivo;
                      if (esParaCotizacion) {
                        ref.read(ventaBorradorProvider.notifier).aplicarDescuento(valor);
                      } else {
                        ref.read(registrarVentaProvider.notifier).seleccionarDescuento(id, nombre, valor);
                      }
                    },
                  ),
                );
              }),
          ],
        );
      },
    );
  }
}
