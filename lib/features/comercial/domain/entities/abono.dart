import 'package:flutter/foundation.dart';

@immutable
class Abono {
  const Abono({
    required this.id,
    required this.cuentaPagarId,
    required this.fecha,
    required this.monto,
    required this.formaPago,
    this.referencia = '',
    this.nota,
  });
  final int id;
  final int cuentaPagarId;
  final DateTime fecha;
  final double monto;
  final String formaPago;
  final String referencia;
  final String? nota;
}
