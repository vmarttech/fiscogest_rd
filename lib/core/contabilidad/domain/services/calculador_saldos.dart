import 'package:fiscogest_rd/core/contabilidad/domain/entities/plan_cuenta.dart';
import 'package:fiscogest_rd/core/contabilidad/domain/entities/linea_asiento.dart';
import 'package:fiscogest_rd/core/contabilidad/domain/enums/tipo_cuenta.dart';

/// Calcula saldos y movimientos de cuentas a partir de líneas de asientos.
class CalculadorSaldos {
  /// Saldo actual de una cuenta a partir de sus movimientos.
  /// Aplica la naturaleza contable: cuentas de activo/gasto aumentan al debe,
  /// pasivo/ingreso/patrimonio al haber.
  double calcularSaldo(
    PlanCuenta cuenta,
    List<LineaAsiento> movimientos,
  ) {
    final debe = _sumarDebe(movimientos);
    final haber = _sumarHaber(movimientos);

    final saldo = cuenta.tipo.esDeudora ? debe - haber : haber - debe;
    // Redondeo a centavos para evitar ruido de punto flotante en saldos.
    return (saldo * 100).roundToDouble() / 100;
  }

  // Solo se consideran lineas validas (monto no negativo, un solo lado, importe > 0).
  double _sumarDebe(List<LineaAsiento> m) => m
      .where((l) => l.esValida)
      .fold(0.0, (s, l) => s + l.debe);
  double _sumarHaber(List<LineaAsiento> m) => m
      .where((l) => l.esValida)
      .fold(0.0, (s, l) => s + l.haber);

  /// Movimientos en un rango de fechas para una lista de asientos filtrados.
  Map<int, double> calcularSaldosPorCuenta(
    List<PlanCuenta> cuentas,
    Map<int, List<LineaAsiento>> movimientosPorCuenta,
  ) {
    final resultado = <int, double>{};
    for (final cuenta in cuentas) {
      final mov = movimientosPorCuenta[cuenta.id] ?? <LineaAsiento>[];
      resultado[cuenta.id] = calcularSaldo(cuenta, mov);
    }
    return resultado;
  }
}
