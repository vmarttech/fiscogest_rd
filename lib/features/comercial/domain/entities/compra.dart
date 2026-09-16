import 'package:fiscogest_rd/features/comercial/data/enums/comercial_enums.dart';

/// Entidad de dominio: Compra de mercancías.
class Compra {
  const Compra({
    required this.id,
    required this.proveedorId,
    required this.nombreProveedor,
    required this.fechaEmision,
    this.fechaVencimiento,
    this.fechaConfirmacion,
    this.fechaRecepcion,
    required this.numeroComprobante,
    this.ncf = '',
    this.tipoComprobante = 'B01',
    this.formaPago = 'contado',
    this.condicionPago = 'contado',
    this.diasCredito = 0,
    required this.subtotalSinImpuestos,
    required this.montoDescuentoGlobal,
    required this.tasaImpuesto,
    required this.montoImpuesto,
    required this.totalCompra,
    this.observaciones = '',
    required this.estado,
    required this.creadoEn,
    this.actualizadoEn,
  });

  final int id;
  final int proveedorId;
  final String nombreProveedor;
  final DateTime fechaEmision;
  final DateTime? fechaVencimiento;
  final DateTime? fechaConfirmacion;
  final DateTime? fechaRecepcion;
  final String numeroComprobante;
  final String ncf;
  final String tipoComprobante;
  final String formaPago;
  final String condicionPago;
  final int diasCredito;
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
    int? id,
    int? proveedorId,
    String? nombreProveedor,
    DateTime? fechaEmision,
    DateTime? fechaVencimiento,
    DateTime? fechaConfirmacion,
    DateTime? fechaRecepcion,
    String? numeroComprobante,
    String? ncf,
    String? tipoComprobante,
    String? formaPago,
    String? condicionPago,
    int? diasCredito,
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
      fechaVencimiento: fechaVencimiento ?? this.fechaVencimiento,
      fechaConfirmacion: fechaConfirmacion ?? this.fechaConfirmacion,
      fechaRecepcion: fechaRecepcion ?? this.fechaRecepcion,
      numeroComprobante: numeroComprobante ?? this.numeroComprobante,
      ncf: ncf ?? this.ncf,
      tipoComprobante: tipoComprobante ?? this.tipoComprobante,
      formaPago: formaPago ?? this.formaPago,
      condicionPago: condicionPago ?? this.condicionPago,
      diasCredito: diasCredito ?? this.diasCredito,
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
  bool get esCredito => formaPago == 'crédito' || formaPago == 'credito';
  bool get estaVencida {
    if (fechaVencimiento == null || !esConfirmada) return false;
    return DateTime.now().isAfter(fechaVencimiento!);
  }
}
