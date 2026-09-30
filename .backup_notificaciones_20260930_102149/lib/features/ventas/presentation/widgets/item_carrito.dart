import 'package:fiscogest_rd/features/ventas/domain/entities/detalle_venta.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/venta_providers.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';
import 'package:fiscogest_rd/core/ui/app_radius.dart';
import 'package:fiscogest_rd/core/ui/status_chip.dart';

String _formatearMonto(double monto) {
  return 'RD\$${NumberFormat('#,##0.00', 'es_DO').format(monto)}';
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Cantidad',
          style: AppTypography.h4.copyWith(fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: controlador,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Cantidad',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            isDense: true,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              final nuevaCantidad =
                  double.tryParse(controlador.text) ?? detalle.cantidad.toDouble();
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
    final notifier = ref.read(registrarVentaProvider.notifier);
    final error = notifier.puedeAplicarDescuentoLinea(detalle);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: AppColors.error,
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Descuento de línea',
            style: AppTypography.h4.copyWith(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('RD\$'),
                      selected: !esPorcentaje,
                      selectedColor: AppColors.primary.withValues(alpha: 0.15),
                      labelStyle: TextStyle(
                        color: !esPorcentaje ? AppColors.primary : AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                      onSelected: (_) => setDialogState(() => esPorcentaje = false),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('%'),
                      selected: esPorcentaje,
                      selectedColor: AppColors.primary.withValues(alpha: 0.15),
                      labelStyle: TextStyle(
                        color: esPorcentaje ? AppColors.primary : AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
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
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  isDense: true,
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
                      backgroundColor: AppColors.error,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
                Navigator.pop(ctx);
              },
              child: const Text('Sin descuento', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                final valor = double.tryParse(controlador.text) ?? 0.0;
                final err = notifier.aplicarDescuentoLinea(indice, valor, esPorcentaje);
                if (err != null && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(err),
                      backgroundColor: AppColors.error,
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

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 420) {
          return _construirModoCompacto(context, ref, tieneOferta, tieneDescuento);
        }
        return _construirModoCompleto(context, ref, tieneOferta, tieneDescuento);
      },
    );
  }

  Widget _construirModoCompleto(
    BuildContext context,
    WidgetRef ref,
    bool tieneOferta,
    bool tieneDescuento,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: AppRadius.allM,
        border: Border.all(color: AppColors.border),
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
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    if (tieneOferta) ...[
                      const SizedBox(width: 6),
                      const StatusChip(label: 'OFERTA', type: StatusChipType.warning, dense: true),
                    ],
                    if (tieneDescuento) ...[
                      const SizedBox(width: 6),
                      const StatusChip(label: 'DESC', type: StatusChipType.success, dense: true),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  'Cant: ${detalle.cantidad}  ·  ${_formatearMonto(detalle.subtotalLinea ?? detalle.subtotal)}',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                ),
                if (tieneOferta && detalle.precioOriginal != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      'Original: ${_formatearMonto(detalle.precioOriginal!)} → Oferta: ${_formatearMonto(detalle.precioUnitario)}',
                      style: AppTypography.labelSmall.copyWith(color: AppColors.warning),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _ActionButton(
            icon: Icons.edit_outlined,
            color: AppColors.primary,
            tooltip: 'Editar cantidad',
            onTap: () => _abrirEditarCantidad(context, ref),
          ),
          _ActionButton(
            icon: Icons.percent,
            color: AppColors.success,
            tooltip: 'Descuento de línea',
            onTap: () => _abrirDescuentoLinea(context, ref),
          ),
          _ActionButton(
            icon: Icons.delete_outline,
            color: AppColors.error,
            tooltip: 'Eliminar',
            onTap: alEliminar,
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: AppRadius.allM,
        border: Border.all(color: AppColors.border),
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
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (tieneOferta) ...[
                const SizedBox(width: 6),
                const StatusChip(label: 'OFERTA', type: StatusChipType.warning, dense: true),
              ],
              if (tieneDescuento) ...[
                const SizedBox(width: 6),
                const StatusChip(label: 'DESC', type: StatusChipType.success, dense: true),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Cant: ${detalle.cantidad}  ·  ${_formatearMonto(detalle.subtotalLinea ?? detalle.subtotal)}',
            style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
          ),
          if (tieneOferta && detalle.precioOriginal != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                'Original: ${_formatearMonto(detalle.precioOriginal!)} → Oferta: ${_formatearMonto(detalle.precioUnitario)}',
                style: AppTypography.labelSmall.copyWith(color: AppColors.warning),
              ),
            ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _ActionButton(
                icon: Icons.edit_outlined,
                color: AppColors.primary,
                tooltip: 'Editar cantidad',
                onTap: () => _abrirEditarCantidad(context, ref),
              ),
              _ActionButton(
                icon: Icons.percent,
                color: AppColors.success,
                tooltip: 'Descuento de línea',
                onTap: () => _abrirDescuentoLinea(context, ref),
              ),
              _ActionButton(
                icon: Icons.delete_outline,
                color: AppColors.error,
                tooltip: 'Eliminar',
                onTap: alEliminar,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {

  const _ActionButton({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, size: 18, color: color),
      tooltip: tooltip,
      onPressed: onTap,
      padding: const EdgeInsets.all(6),
      constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
      visualDensity: VisualDensity.compact,
    );
  }
}
