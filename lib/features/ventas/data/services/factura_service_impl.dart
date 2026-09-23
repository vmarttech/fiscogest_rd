import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/venta.dart';
import 'package:fiscogest_rd/features/ventas/domain/services/i_factura_service.dart';

class FacturaServiceImpl implements IFacturaService {
  FacturaServiceImpl();

  @override
  String generarTextoFactura(Venta venta) {
    final formatoFecha = DateFormat('dd/MM/yyyy HH:mm');
    final formatoNumero = NumberFormat('#,##0.00', 'es_DO');
    String formatearMonto(double valor) => 'RD\$${formatoNumero.format(valor)}';

    final factura = StringBuffer();

    factura.writeln('========================================');
    factura.writeln('           FISCOGEST RD');
    factura.writeln('         FACTURA DE VENTA');
    factura.writeln('========================================');
    factura.writeln('');

    // Número fiscal principal (DGII) + referencia cotización
    if (venta.numeroFactura != null && venta.numeroFactura!.isNotEmpty) {
      factura.writeln('N° Factura: ${venta.numeroFactura}');
      factura.writeln('Ref. Cotización: ${venta.numeroCotizacion}');
    } else {
      factura.writeln('Cotización: ${venta.numeroCotizacion}');
    }

    factura.writeln('Fecha:  ${formatoFecha.format(venta.fecha)}');
    factura.writeln('Cliente ID: ${venta.clienteId}');
    if (venta.nombreCliente != null) {
      factura.writeln('Cliente: ${venta.nombreCliente}');
    }
    factura.writeln('Forma de Pago: ${venta.tipoPago.toUpperCase()}');
    factura.writeln(venta.esCredito ? 'Crédito: SÍ' : 'Crédito: NO');
    factura.writeln('');

    factura.writeln('----------------------------------------');
    factura.writeln('DETALLE DE PRODUCTOS');
    factura.writeln('----------------------------------------');

    for (var i = 0; i < venta.detalles.length; i++) {
      final detalle = venta.detalles[i];
      factura.writeln('${i + 1}. ${detalle.nombreProducto ?? "Producto"}');
      factura.writeln(
        '   Cant: ${detalle.cantidad}  x  ${formatearMonto(detalle.precioUnitario)}',
      );
      if (detalle.descuentoPorcentaje > 0) {
        factura.writeln(
          '   Desc: ${detalle.descuentoPorcentaje.toStringAsFixed(2)}%',
        );
      }
      if (detalle.montoDescuento > 0) {
        factura.writeln(
          '   Desc: ${formatearMonto(detalle.montoDescuento)}',
        );
      }
      final subtotalLinea = detalle.subtotalLinea ?? detalle.subtotal;
      factura.writeln('   Subtotal: ${formatearMonto(subtotalLinea)}');
      factura.writeln('');
    }

    factura.writeln('----------------------------------------');
    factura.writeln(
      'Subtotal:          ${formatearMonto(venta.subtotal)}',
    );
    factura.writeln('ITBIS (18%):       ${formatearMonto(venta.itbis)}');
    factura.writeln('========================================');
    factura.writeln('TOTAL A PAGAR:     ${formatearMonto(venta.total)}');
    factura.writeln('========================================');
    factura.writeln('');
    factura.writeln('');
    factura.writeln('       ¡GRACIAS POR SU COMPRA!');
    factura.writeln('========================================');

    return factura.toString();
  }

  @override
  Future<void> imprimirFactura(Venta venta) async {
    final texto = generarTextoFactura(venta);
    await Clipboard.setData(ClipboardData(text: texto));
  }
}
