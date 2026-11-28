import 'package:fiscogest_rd/core/contabilidad/domain/entities/plan_cuenta.dart';
import 'package:fiscogest_rd/core/contabilidad/domain/entities/linea_asiento.dart';
import 'package:fiscogest_rd/core/contabilidad/domain/enums/tipo_cuenta.dart';

/// Calcula saldos y movimientos de cuentas a partir de líneas de asientos.
/// Todos los montos se manejan en centavos enteros.
class CalculadorSaldos {
  /// Saldo actual de una cuenta a partir de sus movimientos (en centavos).
  /// Aplica la naturaleza contable: cuentas de activo/gasto aumentan al debe,
  /// pasivo/ingreso/patrimonio al haber.
  int calcularSaldo(
    PlanCuenta cuenta,
    List<LineaAsiento> movimientos,
  ) {
    final debe = _sumarDebe(movimientos);
    final haber = _sumarHaber(movimientos);

    final saldo = cuenta.tipo.esDeudora ? debe - haber : haber - debe;
    return saldo;
  }

  int _sumarDebe(List<LineaAsiento> m) =>
      m.where((l) => l.esValida).fold(0, (s, l) => s + l.debeCents);

  int _sumarHaber(List<LineaAsiento> m) =>
      m.where((l) => l.esValida).fold(0, (s, l) => s + l.haberCents);

  /// Saldos por cuenta (en centavos).
  Map<int, int> calcularSaldosPorCuenta(
    List<PlanCuenta> cuentas,
    Map<int, List<LineaAsiento>> movimientosPorCuenta,
  ) {
    final resultado = <int, int>{};
    for (final cuenta in cuentas) {
      final mov = movimientosPorCuenta[cuenta.id] ?? <LineaAsiento>[];
      resultado[cuenta.id] = calcularSaldo(cuenta, mov);
    }
    return resultado;
  }
}
