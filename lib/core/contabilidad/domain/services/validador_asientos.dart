import 'package:fiscogest_rd/core/contabilidad/domain/entities/asiento_contable.dart';
import 'package:fiscogest_rd/core/contabilidad/domain/entities/linea_asiento.dart';
import 'package:fiscogest_rd/core/contabilidad/domain/entities/plan_cuenta.dart';
import 'package:fiscogest_rd/core/contabilidad/domain/enums/estado_asiento.dart';

/// Valida las reglas de negocio de un asiento antes de su registro.
/// Montos en centavos enteros. Si se pasa [cuentasPorId], valida R3:
/// solo cuentas activas de último nivel (permiteMovimiento).
class ValidadorAsientos {
  List<String> validar(
    AsientoContable asiento,
    List<LineaAsiento> lineas, {
    DateTime? referenciaHoy,
    Map<int, PlanCuenta>? cuentasPorId,
  }) {
    final errores = <String>[];

    if (asiento.concepto.trim().isEmpty) {
      errores.add('acct_error_concepto_required');
    }

    final hoy = referenciaHoy ?? DateTime.now();
    final fechaLimite = DateTime(hoy.year, hoy.month, hoy.day);
    final fechaAsiento =
        DateTime(asiento.fecha.year, asiento.fecha.month, asiento.fecha.day);
    if (fechaAsiento.isAfter(fechaLimite)) {
      errores.add('acct_error_future_date');
    }

    if (lineas.length < 2) {
      errores.add('acct_error_min_lines');
    }

    for (var i = 0; i < lineas.length; i++) {
      final linea = lineas[i];
      if (!linea.esValida) {
        errores.add('acct_error_invalid_line:${i + 1}');
        continue;
      }
      // R3: cuenta debe existir, estar activa y permitir movimiento (hoja).
      if (cuentasPorId != null) {
        final cuenta = cuentasPorId[linea.cuentaId];
        if (cuenta == null) {
          errores.add('acct_error_account_not_found:${linea.cuentaId}');
        } else if (!cuenta.activo) {
          errores.add('acct_error_account_inactive:${cuenta.codigo}');
        } else if (!cuenta.permiteMovimiento) {
          errores.add('acct_error_account_not_leaf:${cuenta.codigo}');
        }
      }
    }

    final totalDebe = lineas.fold(0, (s, l) => s + l.debeCents);
    final totalHaber = lineas.fold(0, (s, l) => s + l.haberCents);

    if (totalDebe != totalHaber) {
      errores.add('acct_error_unbalanced:$totalDebe/$totalHaber');
    }
    if (totalDebe <= 0 || totalHaber <= 0) {
      errores.add('acct_error_one_side_only');
    }

    if (asiento.estado == EstadoAsiento.contabilizado) {
      errores.add('acct_error_already_posted');
    }
    if (asiento.estado == EstadoAsiento.anulado) {
      errores.add('acct_error_already_voided');
    }

    return errores;
  }
}
