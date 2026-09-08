import 'package:fiscogest_rd/features/ventas/domain/entities/detalle_venta.dart';

class Venta {
  const Venta({
    required this.id,
    required this.numero,
    required this.clienteId,
    required this.nombreCliente,
    required this.fecha,
    required this.detalles,
    required this.subtotal,
    required this.itbis,
    required this.total,
    required this.tipoPago,
    required this.esCredito,
    this.abonoInicial = 0.0,
    this.vencimiento,
    this.cotizacionOrigenId,
    this.apartadoOrigenId,
    required this.usuarioId,
    this.createdAt,
    this.descuentoId,
    this.descuentoNombre,
    required this.montoDescuento,
  });

  final int? id;
  final String numero;
  final int clienteId;
  final String? nombreCliente;
  final DateTime fecha;
  final List<DetalleVenta> detalles;
  final double subtotal;
  final double itbis;
  final double total;
  final String tipoPago;
  final bool esCredito;
  final double abonoInicial;
  final DateTime? vencimiento;
  final int? cotizacionOrigenId;
  final int? apartadoOrigenId;
  final int? usuarioId;
  final DateTime? createdAt;
  final int? descuentoId;
  final String? descuentoNombre;
  final double montoDescuento;
}
