import 'package:fiscogest_rd/core/contabilidad/domain/enums/lado_movimiento.dart';

/// Entidad de dominio: Línea de un asiento contable (debe / haber sobre una cuenta).
/// Todos los montos se manejan en centavos enteros.
class LineaAsiento {
  const LineaAsiento({
    this.id = 0,
    this.asientoId = 0,
    required this.cuentaId,
    this.debeCents = 0,
    this.haberCents = 0,
    this.concepto,
  });

  final int id;
  final int asientoId;
  final int cuentaId;
  final int debeCents;
  final int haberCents;
  final String? concepto;

  LadoMovimiento get lado {
    if (debeCents > 0) return LadoMovimiento.debe;
    if (haberCents > 0) return LadoMovimiento.haber;
    return LadoMovimiento.debe;
  }

  int get importeCents => debeCents + haberCents;

  /// La línea es válida solo si tiene cuenta, un solo lado > 0 y monto positivo.
  bool get esValida =>
      cuentaId > 0 &&
      debeCents >= 0 &&
      haberCents >= 0 &&
      (debeCents == 0 || haberCents == 0) &&
      importeCents > 0;

  LineaAsiento copyWith({
    int? id,
    int? asientoId,
    int? cuentaId,
    int? debeCents,
    int? haberCents,
    String? concepto,
  }) {
    return LineaAsiento(
      id: id ?? this.id,
      asientoId: asientoId ?? this.asientoId,
      cuentaId: cuentaId ?? this.cuentaId,
      debeCents: debeCents ?? this.debeCents,
      haberCents: haberCents ?? this.haberCents,
      concepto: concepto ?? this.concepto,
    );
  }
}
