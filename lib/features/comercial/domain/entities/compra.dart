import 'package:fiscogest_rd/features/comercial/data/enums/comercial_enums.dart';

class Compra {
  const Compra({
    required this.id,
    required this.numeroComprobante,
    required this.tipoComprobante,
    required this.fechaEmision,
    this.fechaConfirmacion,
    this.fechaVencimiento,
    this.fechaRecepcion,
    this.fechaPago,
    required this.ncf,
    required this.formaPago,
    required this.diasCredito,
    required this.condicionPago,
    required this.subtotalSinImpuestos,
    required this.montoDescuentoGlobal,
    required this.tasaImpuesto,
    required this.montoImpuesto,
    required this.totalCompra,
    required this.proveedorId,
    required this.nombreProveedor,
    required this.estado,
    this.observaciones,
    required this.creadoEn,
    this.actualizadoEn,
  });

  final int id;
  final String numeroComprobante;
  final String tipoComprobante;
  final DateTime fechaEmision;
  final DateTime? fechaConfirmacion;
  final DateTime? fechaVencimiento;
  final DateTime? fechaRecepcion;
  final DateTime? fechaPago;
  final String ncf;
  final String formaPago;
  final int diasCredito;
  final String condicionPago;
  final double subtotalSinImpuestos;
  final double montoDescuentoGlobal;
  final double tasaImpuesto;
  final double montoImpuesto;
  final double totalCompra;
  final int proveedorId;
  final String nombreProveedor;
  final EstadoCompra estado;
  final String? observaciones;
  final DateTime creadoEn;
  final DateTime? actualizadoEn;

  bool get esConfirmada => estado == EstadoCompra.confirmada;

  bool get esCredito {
    final fp = formaPago.toLowerCase();
    final cp = condicionPago.toLowerCase();
    return fp == 'credito' || fp == 'crédito' || cp == 'credito' || cp == 'crédito';
  }

  DateTime? get fechaVencimientoCalculada {
    if (diasCredito <= 0) return fechaVencimiento;
    return fechaVencimiento ?? fechaEmision.add(Duration(days: diasCredito));
  }

  bool get estaVencida {
    if (!esConfirmada) return false;
    final vencimiento = fechaVencimientoCalculada;
    if (vencimiento == null) return false;
    return DateTime.now().isAfter(vencimiento);
  }

  Compra copyWith({
    int? id,
    String? numeroComprobante,
    String? tipoComprobante,
    DateTime? fechaEmision,
    DateTime? fechaConfirmacion,
    DateTime? fechaVencimiento,
    DateTime? fechaRecepcion,
    DateTime? fechaPago,
    String? ncf,
    String? formaPago,
    int? diasCredito,
    String? condicionPago,
    double? subtotalSinImpuestos,
    double? montoDescuentoGlobal,
    double? tasaImpuesto,
    double? montoImpuesto,
    double? totalCompra,
    int? proveedorId,
    String? nombreProveedor,
    EstadoCompra? estado,
    String? observaciones,
    DateTime? creadoEn,
    DateTime? actualizadoEn,
  }) {
    return Compra(
      id: id ?? this.id,
      numeroComprobante: numeroComprobante ?? this.numeroComprobante,
      tipoComprobante: tipoComprobante ?? this.tipoComprobante,
      fechaEmision: fechaEmision ?? this.fechaEmision,
      fechaConfirmacion: fechaConfirmacion ?? this.fechaConfirmacion,
      fechaVencimiento: fechaVencimiento ?? this.fechaVencimiento,
      fechaRecepcion: fechaRecepcion ?? this.fechaRecepcion,
      fechaPago: fechaPago ?? this.fechaPago,
      ncf: ncf ?? this.ncf,
      formaPago: formaPago ?? this.formaPago,
      diasCredito: diasCredito ?? this.diasCredito,
      condicionPago: condicionPago ?? this.condicionPago,
      subtotalSinImpuestos: subtotalSinImpuestos ?? this.subtotalSinImpuestos,
      montoDescuentoGlobal: montoDescuentoGlobal ?? this.montoDescuentoGlobal,
      tasaImpuesto: tasaImpuesto ?? this.tasaImpuesto,
      montoImpuesto: montoImpuesto ?? this.montoImpuesto,
      totalCompra: totalCompra ?? this.totalCompra,
      proveedorId: proveedorId ?? this.proveedorId,
      nombreProveedor: nombreProveedor ?? this.nombreProveedor,
      estado: estado ?? this.estado,
      observaciones: observaciones ?? this.observaciones,
      creadoEn: creadoEn ?? this.creadoEn,
      actualizadoEn: actualizadoEn ?? this.actualizadoEn,
    );
  }
}
