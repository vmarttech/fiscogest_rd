import 'package:fiscogest_rd/features/ventas/domain/entities/detalle_venta.dart';

class Cotizacion {
  const Cotizacion({
    this.id,
    required this.numero,
    required this.clienteId,
    required this.detalles,
    required this.subtotal,
    required this.itbis,
    required this.total,
    required this.validezHasta,
    required this.estado,
    this.createdAt,
  });

  final int? id;
  final String numero;
  final int clienteId;
  final List<DetalleVenta> detalles;
  final double subtotal;
  final double itbis;
  final double total;
  final DateTime validezHasta;
  final String estado;
  final DateTime? createdAt;
}
