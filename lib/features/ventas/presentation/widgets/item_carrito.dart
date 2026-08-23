import 'package:fiscogest_rd/features/ventas/domain/entities/detalle_venta.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/venta_providers.dart';

class ItemCarrito extends ConsumerWidget {
  const ItemCarrito({
    super.key,
    required this.detalle,
    required this.indice,
    required this.alEliminar,
  });

  final DetalleVenta detalle;
  final int indice;
  final VoidCallback alEliminar;

  void _abrirEditarCantidad(BuildContext context, WidgetRef ref) {
    final controlador = TextEditingController(text: detalle.cantidad.toString());
    showDialog<dynamic>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cantidad'),
        content: TextField(
          controller: controlador,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(hintText: 'Cantidad'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              final nuevaCantidad = double.tryParse(controlador.text) ?? detalle.cantidad.toDouble();
              if (nuevaCantidad > 0) {
                ref.read(registrarVentaProvider.notifier).cambiarCantidad(indice, nuevaCantidad);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }

  void _abrirDescuentoLinea(BuildContext context, WidgetRef ref) {
    final tienePorcentaje = detalle.descuentoPorcentaje > 0;
    final tieneMonto = detalle.montoDescuento > 0;
    final controlador = TextEditingController(
      text: tienePorcentaje
          ? detalle.descuentoPorcentaje.toStringAsFixed(2)
          : tieneMonto
              ? detalle.montoDescuento.toStringAsFixed(2)
              : '',
    );
    bool esPorcentaje = tienePorcentaje;
    showDialog<dynamic>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Descuento de línea'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('RD\$'),
                      selected: !esPorcentaje,
                      onSelected: (_) => setDialogState(() => esPorcentaje = false),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('%'),
                      selected: esPorcentaje,
                      onSelected: (_) => setDialogState(() => esPorcentaje = true),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controlador,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  hintText: '0.00',
                  suffixText: esPorcentaje ? '%' : '',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                ref.read(registrarVentaProvider.notifier)
                    .aplicarDescuentoLinea(indice, 0.0, false);
                Navigator.pop(ctx);
              },
              child: const Text('Sin descuento'),
            ),
            TextButton(
              onPressed: () {
                final valor = double.tryParse(controlador.text) ?? 0.0;
                ref.read(registrarVentaProvider.notifier)
                    .aplicarDescuentoLinea(indice, valor, esPorcentaje);
                Navigator.pop(ctx);
              },
              child: const Text('Aceptar'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tieneOferta = detalle.ofertaId != null;
    final tieneDescuento = detalle.descuentoPorcentaje > 0 || detalle.montoDescuento > 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        title: Row(
          children: [
            Text(detalle.nombreProducto ?? ''),
            if (tieneOferta)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'OFERTA',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade700,
                  ),
                ),
              ),
            if (tieneDescuento)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'DESC',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Cant: ${detalle.cantidad} • RD\$ ${(detalle.subtotalLinea ?? detalle.subtotal).toStringAsFixed(2)}'),
            if (tieneOferta && detalle.precioOriginal != null)
              Text(
                'Precio original: RD\$ ${detalle.precioOriginal!.toStringAsFixed(2)} → Oferta: RD\$ ${detalle.precioUnitario.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.orange.shade700,
                ),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, size: 18, color: Colors.blueGrey),
              tooltip: 'Editar cantidad',
              onPressed: () => _abrirEditarCantidad(context, ref),
            ),
            IconButton(
              icon: const Icon(Icons.percent, size: 18, color: Colors.green),
              tooltip: 'Descuento de línea',
              onPressed: () => _abrirDescuentoLinea(context, ref),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
              tooltip: 'Eliminar',
              onPressed: alEliminar,
            ),
          ],
        ),
      ),
    );
  }
}
