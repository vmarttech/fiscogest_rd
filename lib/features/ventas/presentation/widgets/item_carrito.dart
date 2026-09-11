import 'package:fiscogest_rd/features/ventas/domain/entities/detalle_venta.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/venta_providers.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/core/ui/app_spacing.dart';
import 'package:fiscogest_rd/core/ui/app_radius.dart';

String _formatearMonto(double monto) {
  return NumberFormat.currency(
    locale: 'es_DO',
    symbol: '',
    decimalDigits: 2,
  ).format(monto);
}

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
    final controlador = TextEditingController(
      text: detalle.cantidad.toString(),
    );
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
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              final nuevaCantidad =
                  double.tryParse(controlador.text) ??
                  detalle.cantidad.toDouble();
              if (nuevaCantidad > 0) {
                ref
                    .read(registrarVentaProvider.notifier)
                    .cambiarCantidad(indice, nuevaCantidad.toInt());
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

    // ✅ ANTES de abrir el diálogo — validar reglas
    final notifier = ref.read(registrarVentaProvider.notifier);
    final error = notifier.puedeAplicarDescuentoLinea(detalle);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

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
                      onSelected: (_) =>
                          setDialogState(() => esPorcentaje = false),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('%'),
                      selected: esPorcentaje,
                      onSelected: (_) =>
                          setDialogState(() => esPorcentaje = true),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controlador,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
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
                final err = notifier.aplicarDescuentoLinea(indice, 0.0, false);
                if (err != null && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(err),
                      backgroundColor: Colors.redAccent,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
                Navigator.pop(ctx);
              },
              child: const Text('Sin descuento'),
            ),
            TextButton(
              onPressed: () {
                final valor = double.tryParse(controlador.text) ?? 0.0;
                final err = notifier.aplicarDescuentoLinea(
                  indice,
                  valor,
                  esPorcentaje,
                );
                if (err != null && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(err),
                      backgroundColor: Colors.redAccent,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                } else {
                  Navigator.pop(ctx);
                }
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
    final tieneDescuento =
        detalle.descuentoPorcentaje > 0 || detalle.montoDescuento > 0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: LayoutBuilder(
        builder: (context, restricciones) {
          if (restricciones.maxWidth < 420) {
            return _construirModoCompacto(
              context,
              ref,
              tieneOferta,
              tieneDescuento,
            );
          }
          return _construirModoCompleto(
            context,
            ref,
            tieneOferta,
            tieneDescuento,
          );
        },
      ),
    );
  }

  Widget _construirModoCompleto(
    BuildContext context,
    WidgetRef ref,
    bool tieneOferta,
    bool tieneDescuento,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(AppRadius.s),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 4,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        detalle.nombreProducto ?? '',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    if (tieneOferta)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
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
                const SizedBox(height: 2),
                Text(
                  'Cant: ${detalle.cantidad} • RD\$ ${_formatearMonto(detalle.subtotalLinea ?? detalle.subtotal)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (tieneOferta && detalle.precioOriginal != null)
                  Text(
                    'Precio original: RD\$ ${_formatearMonto(detalle.precioOriginal!)} → Oferta: RD\$ ${_formatearMonto(detalle.precioUnitario)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange.shade700,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit, size: 18, color: Colors.blueGrey),
                tooltip: 'Editar cantidad',
                onPressed: () => _abrirEditarCantidad(context, ref),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
              IconButton(
                icon: const Icon(Icons.percent, size: 18, color: Colors.green),
                tooltip: 'Descuento de línea',
                onPressed: () => _abrirDescuentoLinea(context, ref),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
              IconButton(
                icon: const Icon(
                  Icons.delete_outline,
                  size: 18,
                  color: Colors.red,
                ),
                tooltip: 'Eliminar',
                onPressed: alEliminar,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _construirModoCompacto(
    BuildContext context,
    WidgetRef ref,
    bool tieneOferta,
    bool tieneDescuento,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(AppRadius.s),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  detalle.nombreProducto ?? '',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
              if (tieneOferta)
                Container(
                  margin: const EdgeInsets.only(left: 6),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'OFERTA',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade700,
                    ),
                  ),
                ),
              if (tieneDescuento)
                Container(
                  margin: const EdgeInsets.only(left: 6),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'DESC',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Cant: ${detalle.cantidad} • RD\$ ${_formatearMonto(detalle.subtotalLinea ?? detalle.subtotal)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (tieneOferta && detalle.precioOriginal != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                'Precio original: RD\$ ${_formatearMonto(detalle.precioOriginal!)} → Oferta: RD\$ ${_formatearMonto(detalle.precioUnitario)}',
                style: TextStyle(fontSize: 11, color: Colors.orange.shade700),
              ),
            ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                icon: const Icon(Icons.edit, size: 18, color: Colors.blueGrey),
                tooltip: 'Editar cantidad',
                onPressed: () => _abrirEditarCantidad(context, ref),
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
              IconButton(
                icon: const Icon(Icons.percent, size: 18, color: Colors.green),
                tooltip: 'Descuento de línea',
                onPressed: () => _abrirDescuentoLinea(context, ref),
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
              IconButton(
                icon: const Icon(
                  Icons.delete_outline,
                  size: 18,
                  color: Colors.red,
                ),
                tooltip: 'Eliminar',
                onPressed: alEliminar,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
