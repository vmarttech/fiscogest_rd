import 'package:flutter/material.dart';
import 'package:fiscogest_rd/core/ui/app_formatters.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/venta_borrador_provider.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/registrar_venta_provider.dart';

class SelectorDescuentoDialog extends ConsumerStatefulWidget {

  const SelectorDescuentoDialog({
    super.key,
    this.esParaCotizacion = false,
  });
  final bool esParaCotizacion;

  @override
  ConsumerState<SelectorDescuentoDialog> createState() => _SelectorDescuentoDialogState();
}

class _SelectorDescuentoDialogState extends ConsumerState<SelectorDescuentoDialog> {
  @override
  Widget build(BuildContext context) {
    final estadoVenta = ref.watch(registrarVentaProvider);
    final estadoCot = ref.watch(ventaBorradorProvider);
    final String? descuentoNombre = widget.esParaCotizacion
        ? estadoCot.descuentoNombre
        : estadoVenta.descuentoNombre;
    final double montoDescuento = widget.esParaCotizacion
        ? estadoCot.montoDescuento
        : estadoVenta.montoDescuento;

    return AlertDialog(
      title: const Text('Descuento Aplicado'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Nombre: ${descuentoNombre ?? "Ninguno"}'),
          const SizedBox(height: 8),
          Text('Monto: ${formatRd(montoDescuento)}'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cerrar'),
        ),
      ],
    );
  }
}
