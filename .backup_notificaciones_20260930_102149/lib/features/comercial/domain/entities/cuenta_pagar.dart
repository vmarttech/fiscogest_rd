import 'package:flutter/foundation.dart';
import 'package:fiscogest_rd/features/comercial/data/enums/comercial_enums.dart';

@immutable
class CuentaPagar {

  const CuentaPagar({
    required this.id,
    required this.compraId,
    required this.nombreProveedor,
    required this.numeroDocumento,
    this.fechaEmision,
    this.fechaVencimiento,
    required this.montoTotal,
    required this.montoAbonado,
    required this.estado,
  });
  final int id;
  final int compraId;
  final String nombreProveedor;
  final String numeroDocumento;
  final DateTime? fechaEmision;
  final DateTime? fechaVencimiento;
  final double montoTotal;
  final double montoAbonado;
  final PagarEstado estado;

  double get saldoPendiente => montoTotal - montoAbonado;

  bool get estaVencida {
    if (estado == PagarEstado.pagado) return false;
    final DateTime? venc = fechaVencimiento;
    if (venc == null) return false;
    return DateTime.now().isAfter(venc);
  }

  CuentaPagar copyWith({
    int? id,
    int? compraId,
    String? nombreProveedor,
    String? numeroDocumento,
    DateTime? fechaEmision,
    DateTime? fechaVencimiento,
    double? montoTotal,
    double? montoAbonado,
    PagarEstado? estado,
  }) {
    return CuentaPagar(
      id: id ?? this.id,
      compraId: compraId ?? this.compraId,
      nombreProveedor: nombreProveedor ?? this.nombreProveedor,
      numeroDocumento: numeroDocumento ?? this.numeroDocumento,
      fechaEmision: fechaEmision ?? this.fechaEmision,
      fechaVencimiento: fechaVencimiento ?? this.fechaVencimiento,
      montoTotal: montoTotal ?? this.montoTotal,
      montoAbonado: montoAbonado ?? this.montoAbonado,
      estado: estado ?? this.estado,
    );
  }
}
