import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/venta.dart';
import 'package:fiscogest_rd/core/ui/fisco_gest_notifications.dart';

class FacturaImprimible extends StatelessWidget {
  const FacturaImprimible({
    super.key,
    required this.venta,
    required this.onCerrar,
  });

  final Venta venta;
  final VoidCallback onCerrar;

  String _formatearMonto(double valor) {
    return 'RD\$${NumberFormat('#,##0.00', 'es_DO').format(valor)}';
  }

  String _formatearFecha(DateTime fecha) {
    return DateFormat('dd/MM/yyyy HH:mm').format(fecha);
  }

  double get _descuentoTotal {
    return venta.detalles.fold<double>(0.0, (suma, elemento) {
      final linea = elemento;
      return suma + linea.montoDescuento;
    });
  }

  double get _baseGravable => venta.subtotal - _descuentoTotal;

  @override
  Widget build(BuildContext context) {
    final esCredito = venta.esCredito;
    final descuentoTotal = _descuentoTotal;
    final baseGravable = _baseGravable;
    final tieneNumeroFactura =
        venta.numeroFactura != null && venta.numeroFactura!.isNotEmpty;

    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              '========================================',
              style: TextStyle(fontFamily: 'Courier', fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            const Text(
              '           FISCOGEST RD',
              style: TextStyle(
                fontFamily: 'Courier',
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const Text(
              '         FACTURA DE VENTA',
              style: TextStyle(fontFamily: 'Courier', fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            const Text(
              '========================================',
              style: TextStyle(fontFamily: 'Courier', fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            // Número fiscal principal (DGII) + referencia cotización
            if (tieneNumeroFactura) ...[
              Text(
                'N° Factura: ${venta.numeroFactura}',
                style: const TextStyle(fontFamily: 'Courier', fontSize: 12),
              ),
              Text(
                'Ref. Cotización: ${venta.numeroCotizacion}',
                style: const TextStyle(fontFamily: 'Courier', fontSize: 12),
              ),
            ] else
              Text(
                'Cotización: ${venta.numeroCotizacion}',
                style: const TextStyle(fontFamily: 'Courier', fontSize: 12),
              ),

            Text(
              'Fecha:   ${_formatearFecha(venta.fecha)}',
              style: const TextStyle(fontFamily: 'Courier', fontSize: 12),
            ),
            Text(
              'Cliente ID: ${venta.clienteId}',
              style: const TextStyle(fontFamily: 'Courier', fontSize: 12),
            ),
            if (venta.nombreCliente != null)
              Text(
                'Cliente: ${venta.nombreCliente}',
                style: const TextStyle(fontFamily: 'Courier', fontSize: 12),
              ),
            Text(
              'Forma de Pago: ${venta.tipoPago.toUpperCase()}',
              style: const TextStyle(fontFamily: 'Courier', fontSize: 12),
            ),
            Text(
              'Crédito: ${esCredito ? "SÍ" : "NO"}',
              style: const TextStyle(fontFamily: 'Courier', fontSize: 12),
            ),
            const SizedBox(height: 8),
            const Text(
              '----------------------------------------',
              style: TextStyle(fontFamily: 'Courier', fontSize: 12),
            ),
            const SizedBox(height: 8),
            const Text(
              'DETALLE DE PRODUCTOS',
              style: TextStyle(
                fontFamily: 'Courier',
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '----------------------------------------',
              style: TextStyle(fontFamily: 'Courier', fontSize: 12),
            ),
            const SizedBox(height: 8),
            ...venta.detalles.asMap().entries.map((entry) {
              final indice = entry.key;
              final linea = entry.value;
              final nombre = linea.nombreProducto ?? 'Producto';
              final tieneDescuento = linea.montoDescuento != 0.0;
              final cantidad = linea.cantidad;
              final subtotalLinea = linea.subtotalLinea ?? linea.subtotal;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${indice + 1}. $nombre',
                    style: const TextStyle(fontFamily: 'Courier', fontSize: 12),
                  ),
                  Text(
                    '   Cant: $cantidad  x  ${_formatearMonto(linea.precioUnitario)}',
                    style: const TextStyle(fontFamily: 'Courier', fontSize: 12),
                  ),
                  Text(
                    '   Subtotal: ${_formatearMonto(subtotalLinea)}',
                    style: const TextStyle(fontFamily: 'Courier', fontSize: 12),
                  ),
                  if (tieneDescuento)
                    Text(
                      '   Descuento: -${_formatearMonto(linea.montoDescuento)}',
                      style: const TextStyle(
                        fontFamily: 'Courier',
                        fontSize: 12,
                        color: Colors.green,
                      ),
                    ),
                  const SizedBox(height: 4),
                ],
              );
            }),
            const SizedBox(height: 8),
            const Text(
              '----------------------------------------',
              style: TextStyle(fontFamily: 'Courier', fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              'Subtotal:          ${_formatearMonto(venta.subtotal)}',
              style: const TextStyle(fontFamily: 'Courier', fontSize: 12),
            ),
            if (descuentoTotal != 0.0) ...[
              Text(
                'Descuento:         -${_formatearMonto(descuentoTotal)}',
                style: const TextStyle(
                  fontFamily: 'Courier',
                  fontSize: 12,
                  color: Colors.green,
                ),
              ),
              Text(
                'Base Gravable:     ${_formatearMonto(baseGravable)}',
                style: const TextStyle(fontFamily: 'Courier', fontSize: 12),
              ),
            ],
            Text(
              'ITBIS (18%):       ${_formatearMonto(venta.itbis)}',
              style: const TextStyle(fontFamily: 'Courier', fontSize: 12),
            ),
            const SizedBox(height: 4),
            const Text(
              '========================================',
              style: TextStyle(fontFamily: 'Courier', fontSize: 12),
            ),
            Text(
              'TOTAL A PAGAR:     ${_formatearMonto(venta.total)}',
              style: const TextStyle(
                fontFamily: 'Courier',
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Text(
              '========================================',
              style: TextStyle(fontFamily: 'Courier', fontSize: 12),
            ),
            const Text(' '),
            const SizedBox(height: 16),
            const Text(
              '       ¡GRACIAS POR SU COMPRA!',
              style: TextStyle(fontFamily: 'Courier', fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () {
                    final contenido = _generarTextoFactura(
                      descuentoTotal,
                      baseGravable,
                    );
                    Clipboard.setData(ClipboardData(text: contenido));
                    FiscoGestNotifications.show(
                      const SnackBar(
                        content: Text('Factura copiada al portapapeles'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.copy, size: 16),
                  label: const Text('Copiar'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: onCerrar,
                  icon: const Icon(Icons.check_circle_outline, size: 16),
                  label: const Text('Cerrar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _generarTextoFactura(double descuentoTotal, double baseGravable) {
    final buffer = StringBuffer();
    buffer.writeln('========================================');
    buffer.writeln('           FISCOGEST RD');
    buffer.writeln('         FACTURA DE VENTA');
    buffer.writeln('========================================');

    // Número fiscal principal (DGII) + referencia cotización
    if (venta.numeroFactura != null && venta.numeroFactura!.isNotEmpty) {
      buffer.writeln('N° Factura: ${venta.numeroFactura}');
      buffer.writeln('Ref. Cotización: ${venta.numeroCotizacion}');
    } else {
      buffer.writeln('Cotización: ${venta.numeroCotizacion}');
    }

    buffer.writeln('Fecha:   ${_formatearFecha(venta.fecha)}');
    buffer.writeln('Cliente ID: ${venta.clienteId}');
    if (venta.nombreCliente != null) {
      buffer.writeln('Cliente: ${venta.nombreCliente}');
    }
    buffer.writeln('Forma de Pago: ${venta.tipoPago.toUpperCase()}');
    buffer.writeln('Crédito: ${venta.esCredito ? "SÍ" : "NO"}');
    buffer.writeln('----------------------------------------');
    buffer.writeln('DETALLE DE PRODUCTOS');
    buffer.writeln('----------------------------------------');
    for (var i = 0; i < venta.detalles.length; i++) {
      final linea = venta.detalles[i];
      final nombre = linea.nombreProducto ?? 'Producto';
      final subtotalLinea = linea.subtotalLinea ?? linea.subtotal;
      buffer.writeln('${i + 1}. $nombre');
      buffer.writeln(
        '   Cant: ${linea.cantidad}  x  ${_formatearMonto(linea.precioUnitario)}',
      );
      buffer.writeln('   Subtotal: ${_formatearMonto(subtotalLinea)}');
      if (linea.montoDescuento != 0.0) {
        buffer.writeln(
          '   Descuento: -${_formatearMonto(linea.montoDescuento)}',
        );
      }
    }
    buffer.writeln('----------------------------------------');
    buffer.writeln('Subtotal:          ${_formatearMonto(venta.subtotal)}');
    if (descuentoTotal != 0.0) {
      buffer.writeln('Descuento:         -${_formatearMonto(descuentoTotal)}');
      buffer.writeln('Base Gravable:     ${_formatearMonto(baseGravable)}');
    }
    buffer.writeln('ITBIS (18%):       ${_formatearMonto(venta.itbis)}');
    buffer.writeln('========================================');
    buffer.writeln('TOTAL A PAGAR:     ${_formatearMonto(venta.total)}');
    buffer.writeln('========================================');
    buffer.writeln('       ¡GRACIAS POR SU COMPRA!');
    return buffer.toString();
  }
}
