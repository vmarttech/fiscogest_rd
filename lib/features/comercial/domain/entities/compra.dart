import 'package:fiscogest_rd/features/comercial/data/enums/comercial_enums.dart';

/// Entidad de dominio: Compra de mercancías.
///
/// Encabezado de operación de compra realizada a proveedor,
/// con totales, impuestos y estado.
class Compra {
  const Compra({
    required this.id,
    required this.proveedorId,
    required this.nombreProveedor,
    required this.fechaEmision,
    this.fechaConfirmacion,
    required this.numeroComprobante,
    required this.subtotalSinImpuestos,
    required this.montoDescuentoGlobal,
    required this.tasaImpuesto,
    required this.montoImpuesto,
    required this.totalCompra,
    required this.observaciones,
    required this.estado,
    required this.creadoEn,
    this.actualizadoEn,
  });

  final String id;
  final String proveedorId;
  final String nombreProveedor;
  final DateTime fechaEmision;
  final DateTime? fechaConfirmacion;
  final String numeroComprobante;
  final double subtotalSinImpuestos;
  final double montoDescuentoGlobal;
  final double tasaImpuesto;
  final double montoImpuesto;
  final double totalCompra;
  final String observaciones;
  final EstadoCompra estado;
  final DateTime creadoEn;
  final DateTime? actualizadoEn;

  Compra copyWith({
    String? id,
    String? proveedorId,
    String? nombreProveedor,
    DateTime? fechaEmision,
    DateTime? fechaConfirmacion,
    String? numeroComprobante,
    double? subtotalSinImpuestos,
    double? montoDescuentoGlobal,
    double? tasaImpuesto,
    double? montoImpuesto,
    double? totalCompra,
    String? observaciones,
    EstadoCompra? estado,
    DateTime? creadoEn,
    DateTime? actualizadoEn,
  }) {
    return Compra(
      id: id ?? this.id,
      proveedorId: proveedorId ?? this.proveedorId,
      nombreProveedor: nombreProveedor ?? this.nombreProveedor,
      fechaEmision: fechaEmision ?? this.fechaEmision,
      fechaConfirmacion: fechaConfirmacion ?? this.fechaConfirmacion,
      numeroComprobante: numeroComprobante ?? this.numeroComprobante,
      subtotalSinImpuestos: subtotalSinImpuestos ?? this.subtotalSinImpuestos,
      montoDescuentoGlobal: montoDescuentoGlobal ?? this.montoDescuentoGlobal,
      tasaImpuesto: tasaImpuesto ?? this.tasaImpuesto,
      montoImpuesto: montoImpuesto ?? this.montoImpuesto,
      totalCompra: totalCompra ?? this.totalCompra,
      observaciones: observaciones ?? this.observaciones,
      estado: estado ?? this.estado,
      creadoEn: creadoEn ?? this.creadoEn,
      actualizadoEn: actualizadoEn ?? this.actualizadoEn,
    );
  }

  bool get esConfirmada => estado == EstadoCompra.confirmada;
  bool get esBorrador => estado == EstadoCompra.borrador;
}
