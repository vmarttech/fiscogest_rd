import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/venta.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/detalle_venta.dart';
import 'package:fiscogest_rd/features/ventas/domain/services/i_factura_service.dart';

class FacturaServiceImpl implements IFacturaService {
  FacturaServiceImpl();

  @override
  String generarTextoFactura(Venta venta) {
    final formatoFecha = DateFormat('dd/MM/yyyy HH:mm');
    final formatoMoneda = NumberFormat.currency(locale: 'es_DO', symbol: 'RD\$ ', decimalDigits: 2);
    final factura = StringBuffer();
    factura.writeln('========================================');
    factura.writeln('           FISCOGEST RD');
    factura.writeln('         FACTURA DE VENTA');
    factura.writeln('========================================');
    factura.writeln('');
    factura.writeln('Número: ${venta.numero}');
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
      final detalle = venta.detalles[i] as DetalleVenta;
      factura.writeln('${i + 1}. ${detalle.nombreProducto ?? "Producto"}');
      factura.writeln('   Cant: ${detalle.cantidad}  x  ${formatoMoneda.format(detalle.precioUnitario)}');
      if (detalle.descuentoPorcentaje > 0) {
        factura.writeln('   Desc: ${detalle.descuentoPorcentaje.toStringAsFixed(2)}%');
      }
      if (detalle.montoDescuento > 0) {
        factura.writeln('   Desc: ${formatoMoneda.format(detalle.montoDescuento)}');
      }
      final subtotalLinea = detalle.subtotalLinea ?? detalle.subtotal;
      factura.writeln('   Subtotal: ${formatoMoneda.format(subtotalLinea)}');
      factura.writeln('');
    }
    factura.writeln('----------------------------------------');
    factura.writeln('Subtotal:          ${formatoMoneda.format(venta.subtotal)}');
    factura.writeln('ITBIS (18%):       ${formatoMoneda.format(venta.itbis)}');
    factura.writeln('========================================');
    factura.writeln('TOTAL A PAGAR:     ${formatoMoneda.format(venta.total)}');
    factura.writeln('========================================');
    factura.writeln('');
    factura.writeln('Usuario ID: ${venta.usuarioId ?? "N/A"}');
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
