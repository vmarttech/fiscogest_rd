import 'package:fiscogest_rd/core/contabilidad/domain/enums/lado_movimiento.dart';

/// Entidad de dominio: Linea de un asiento contable (debe / haber sobre una cuenta).
class LineaAsiento {
  const LineaAsiento({
    this.id = 0,
    this.asientoId = 0,
    required this.cuentaId,
    this.debe = 0.0,
    this.haber = 0.0,
    this.concepto,
  });

  final int id;
  final int asientoId;
  final int cuentaId;
  final double debe;
  final double haber;
  final String? concepto;

  // Lado efectivo; en una linea invalida (sin importe) se asume debe por defecto.
  LadoMovimiento get lado {
    if (debe > 0) return LadoMovimiento.debe;
    if (haber > 0) return LadoMovimiento.haber;
    return LadoMovimiento.debe;
  }

  double get importe => debe + haber;

  // La linea debe tener cuenta valida, montos finitos, no cargar debe y haber
  // a la vez, y su importe debe ser mayor que cero.
  bool get esValida =>
      cuentaId > 0 &&
      debe.isFinite &&
      haber.isFinite &&
      debe >= 0 &&
      haber >= 0 &&
      (debe == 0 || haber == 0) &&
      importe > 0;

  // Importe redondeado a centavos para evitar ruido de punto flotante.
  double get importeCents => (importe * 100).roundToDouble() / 100;

  LineaAsiento copyWith({
    int? id,
    int? asientoId,
    int? cuentaId,
    double? debe,
    double? haber,
    String? concepto,
  }) {
    return LineaAsiento(
      id: id ?? this.id,
      asientoId: asientoId ?? this.asientoId,
      cuentaId: cuentaId ?? this.cuentaId,
      debe: debe ?? this.debe,
      haber: haber ?? this.haber,
      concepto: concepto ?? this.concepto,
    );
  }
}
