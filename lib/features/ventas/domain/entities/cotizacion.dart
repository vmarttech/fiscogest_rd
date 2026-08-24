import 'package:fiscogest_rd/features/ventas/domain/entities/detalle_venta.dart';

class Cotizacion {
  const Cotizacion({
    this.id,
    required this.numero,
    required this.clienteId,
    this.nombreCliente,
    required this.detalles,
    required this.subtotal,
    required this.itbis,
    required this.total,
    required this.validezHasta,
    required this.estado,
    this.usuarioId,
    this.createdAt,
  });

  final int? id;
  final String numero;
  final int clienteId;
  final String? nombreCliente;
  final List<DetalleVenta> detalles;
  final double subtotal;
  final double itbis;
  final double total;
  final DateTime validezHasta;
  final String estado;
  final int? usuarioId;
  final DateTime? createdAt;

  Cotizacion copyWith({
    int? id,
    String? numero,
    int? clienteId,
    String? nombreCliente,
    List<DetalleVenta>? detalles,
    double? subtotal,
    double? itbis,
    double? total,
    DateTime? validezHasta,
    String? estado,
    int? usuarioId,
    DateTime? createdAt,
  }) {
    return Cotizacion(
      id: id ?? this.id,
      numero: numero ?? this.numero,
      clienteId: clienteId ?? this.clienteId,
      nombreCliente: nombreCliente ?? this.nombreCliente,
      detalles: detalles ?? this.detalles,
      subtotal: subtotal ?? this.subtotal,
      itbis: itbis ?? this.itbis,
      total: total ?? this.total,
      validezHasta: validezHasta ?? this.validezHasta,
      estado: estado ?? this.estado,
      usuarioId: usuarioId ?? this.usuarioId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
