import 'package:fiscogest_rd/features/ventas/domain/entities/venta.dart';

class Apartado {
  const Apartado({
    this.id,
    required this.numero,
    required this.clienteId,
    required this.productos,
    required this.montoTotal,
    required this.montoAbonado,
    required this.saldoPendiente,
    required this.fechaApartado,
    this.fechaLimitePago,
    required this.estado,
    this.createdAt,
  });

  final int? id;
  final String numero;
  final int clienteId;
  final List<DetalleVenta> productos;
  final double montoTotal;
  final double montoAbonado;
  final double saldoPendiente;
  final DateTime fechaApartado;
  final DateTime? fechaLimitePago;
  final String estado;
  final DateTime? createdAt;
}
