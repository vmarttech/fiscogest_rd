import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/descuento.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/venta_providers.dart';

class SelectorDescuento extends ConsumerWidget {
  const SelectorDescuento({super.key});

  String _formatearValor(Descuento descuento) {
    if (descuento.tipo == 'porcentaje') {
      return '${descuento.valor.toStringAsFixed(0)}%';
    } else if (descuento.tipo == 'monto') {
      return 'RD\$ ${descuento.valor.toStringAsFixed(2)}';
    }
    return descuento.valor.toString();
  }

  String _formatearAplicaA(Descuento descuento) {
    switch (descuento.aplicaA) {
      case 'todo':
        return 'Aplica a toda la venta';
      case 'categoria':
        return 'Por categoría';
      case 'producto':
        return 'Por producto específico';
      case 'cliente':
        return 'Por cliente';
      default:
        return descuento.aplicaA;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final descuentosAsync = ref.watch(descuentosActivosProvider);
    final estadoVenta = ref.watch(registrarVentaProvider);

    return descuentosAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 8),
            Text('Error al cargar descuentos: $error'),
          ],
        ),
      ),
      data: (descuentos) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (estadoVenta.descuentoId != null)
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
                          'Descuento aplicado: ${estadoVenta.descuentoNombre}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        Text(
                          'Monto: RD\$ ${estadoVenta.montoDescuento.toStringAsFixed(2)}',
                          style: const TextStyle(color: Colors.green),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: () {
                        ref.read(registrarVentaProvider.notifier).quitarDescuento();
                      },
                      child: const Text('Quitar'),
                    ),
                  ],
                ),
              ),
            if (descuentos.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(
                  child: Text('No hay descuentos vigentes disponibles'),
                ),
              )
            else
              ...descuentos.map((descuento) {
                final seleccionado = estadoVenta.descuentoId == descuento.id;
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
                      descuento.nombre,
                      style: TextStyle(
                        fontWeight: seleccionado ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    subtitle: Text(_formatearAplicaA(descuento)),
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
                          descuento.tipo,
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                    onTap: () {
                      ref.read(registrarVentaProvider.notifier).aplicarDescuento(descuento);
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
