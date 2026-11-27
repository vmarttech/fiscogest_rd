import 'package:fiscogest_rd/core/contabilidad/domain/entities/asiento_contable.dart';
import 'package:fiscogest_rd/core/contabilidad/domain/entities/linea_asiento.dart';
import 'package:fiscogest_rd/core/contabilidad/domain/enums/estado_asiento.dart';

/// Valida las reglas de negocio de un asiento antes de su registro.
class ValidadorAsientos {
  static const double toleranciaCentavos = 0.005;

  /// Devuelve lista de errores vacía = el asiento es válido para registrar.
  List<String> validar(
    AsientoContable asiento,
    List<LineaAsiento> lineas, {
    DateTime? referenciaHoy,
  }) {
    final errores = <String>[];

    // 1. Concepto no vacío
    if (asiento.concepto.trim().isEmpty) {
      errores.add('acct_error_concepto_required');
    }

    // 1b. La fecha no puede ser futura (se admite el dia de hoy)
    final hoy = referenciaHoy ?? DateTime.now();
    final fechaLimite = DateTime(hoy.year, hoy.month, hoy.day);
    final fechaAsiento = DateTime(asiento.fecha.year, asiento.fecha.month, asiento.fecha.day);
    if (fechaAsiento.isAfter(fechaLimite)) {
      errores.add('acct_error_future_date');
    }

    // 2. Al menos dos líneas
    if (lineas.length < 2) {
      errores.add('acct_error_min_lines');
    }

    // 3. Cada línea es válida
    for (var i = 0; i < lineas.length; i++) {
      final linea = lineas[i];
      if (!linea.esValida) {
        errores.add('acct_error_invalid_line:${i + 1}');
      }
    }

    // 4. El asiento está cuadrado (montos redondeados a centavos)
    final totalDebe = lineas.fold(0.0, (s, l) => s + l.debe);
    final totalHaber = lineas.fold(0.0, (s, l) => s + l.haber);
    final debeCents = (totalDebe * 100).roundToDouble() / 100;
    final haberCents = (totalHaber * 100).roundToDouble() / 100;
    final diferencia = (debeCents - haberCents).abs();

    if (diferencia > toleranciaCentavos) {
      errores.add('acct_error_unbalanced:${debeCents.toStringAsFixed(2)}/${haberCents.toStringAsFixed(2)}');
    }

    // 4b. Ambos lados con movimiento: el asiento no puede ser todo cero ni de un solo lado
    if (debeCents <= toleranciaCentavos || haberCents <= toleranciaCentavos) {
      errores.add('acct_error_one_side_only');
    }

    // 5. No se registran asientos ya contabilizados ni anulados (R5: inmutabilidad)
    if (asiento.estado == EstadoAsiento.contabilizado) {
      errores.add('acct_error_already_posted');
    }
    if (asiento.estado == EstadoAsiento.anulado) {
      errores.add('acct_error_already_voided');
    }

    return errores;
  }
}
