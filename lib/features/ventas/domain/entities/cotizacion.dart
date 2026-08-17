import 'package:fiscogest_rd/features/ventas/domain/entities/venta.dart';

class Cotizacion {

  const Cotizacion({
    this.id,
    required this.numero,
    required this.clienteId,
    required this.fechaEmision,
    required this.fechaVencimiento,
    required this.detalles,
    required this.subtotal,
    required this.itbis,
    required this.total,
    this.convertidaAVenta = false,
    this.ventaId,
    this.createdAt,
  });
  final String? id;
  final String numero;
  final String clienteId;
  final DateTime fechaEmision;
  final DateTime fechaVencimiento;
  final List<DetalleVenta> detalles;
  final double subtotal;
  final double itbis;
  final double total;
  final bool convertidaAVenta;
  final String? ventaId;
  final DateTime? createdAt;
}
