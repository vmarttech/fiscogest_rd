import 'package:intl/intl.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/venta.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/detalle_venta.dart';
import 'package:fiscogest_rd/features/configuracion/domain/entities/configuracion_entity.dart';

/// Genera un recibo de texto estilizado optimizado para WhatsApp / redes.
/// Pensado para comercios informales: liviano, legible y sin PDF.
String generarReciboDigital({
  required Venta venta,
  required ConfiguracionEntity? empresa,
  String mensajeCierre = '¡Dios bendiga tu día! Vuélvenos a visitar.',
}) {
  final buffer = StringBuffer();
  final nombreNegocio = (empresa?.nombreComercial.trim().isNotEmpty == true)
      ? empresa!.nombreComercial.trim()
      : (empresa?.razonSocial.trim().isNotEmpty == true
          ? empresa!.razonSocial.trim()
          : 'Nuestro negocio');

  final numero = (venta.numeroFactura?.trim().isNotEmpty == true)
      ? venta.numeroFactura!.trim()
      : venta.numeroCotizacion;

  final tipo = (venta.numeroFactura?.trim().isNotEmpty == true)
      ? 'Factura'
      : 'Consumo';

  final fechaStr = DateFormat('dd/MM/yyyy HH:mm').format(venta.fecha);

  buffer.writeln('🛍️ ¡Gracias por tu compra en $nombreNegocio!');
  buffer.writeln('----------------------------------');
  buffer.writeln('Doc: #$numero ($tipo)');
  buffer.writeln('Fecha: $fechaStr');
  if (venta.nombreCliente != null && venta.nombreCliente!.trim().isNotEmpty) {
    buffer.writeln('Cliente: ${venta.nombreCliente!.trim()}');
  }
  buffer.writeln('----------------------------------');

  for (final DetalleVenta d in venta.detalles) {
    final nombre = (d.nombreProducto ?? 'Ítem').trim();
    final nombreCorto = nombre.length > 20
        ? '${nombre.substring(0, 17)}...'
        : nombre.padRight(20);
    final subtotal = d.subtotalLinea ?? d.subtotal;
    final monto = 'RD\$ ${subtotal.toStringAsFixed(2)}';
    buffer.writeln('${d.cantidad}x $nombreCorto - $monto');
  }

  buffer.writeln('----------------------------------');

  if (venta.montoDescuento > 0.009) {
    buffer.writeln('Descuento: -RD\$ ${venta.montoDescuento.toStringAsFixed(2)}');
  }
  if (venta.itbis > 0.009) {
    buffer.writeln('ITBIS: RD\$ ${venta.itbis.toStringAsFixed(2)}');
  }
  if (venta.costoEnvio > 0.009) {
    buffer.writeln('Envío: RD\$ ${venta.costoEnvio.toStringAsFixed(2)}');
  }

  buffer.writeln('TOTAL: RD\$ ${venta.montoTotal.toStringAsFixed(2)}');
  buffer.writeln('Forma de Pago: ${venta.formaPago}');
  buffer.writeln('----------------------------------');
  buffer.writeln(mensajeCierre);

  return buffer.toString();
}
