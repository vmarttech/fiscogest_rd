import 'package:fiscogest_rd/features/creditos/domain/entities/cuenta_por_cobrar.dart';
import 'package:fiscogest_rd/features/creditos/domain/entities/cuota.dart';

/// Liquidación anticipada estilo bancario:
/// - Descuento **solo sobre intereses** de cuotas no pagadas.
/// - El capital se paga completo.
/// - Mínimo [minCuotasPendientes] cuotas pendientes.
/// - El acuerdo no altera el plan hasta que se cobre la liquidación.
class ProntoPagoService {
  static const int minCuotasPendientes = 3;
  static const String markerPrefix = 'PRONTO_PAGO|';

  static List<Cuota> cuotasPendientes(CuentaPorCobrar c) {
    final plan = c.planPago;
    if (plan == null || plan.cuotas.isEmpty) return const [];
    return plan.cuotas.where((q) => !q.pagada).toList();
  }

  static ProntoPagoCalculo calcular(
    CuentaPorCobrar c, {
    double descuentoInteresPct = 0,
  }) {
    final pend = cuotasPendientes(c);
    final capital = pend.fold<double>(0, (s, q) => s + q.montoCapital);
    final interes = pend.fold<double>(0, (s, q) => s + q.montoInteres);
    final pct = descuentoInteresPct.clamp(0.0, 100.0);
    final interesConDesc = interes * (1 - pct / 100);
    final descuentoMonto = interes - interesConDesc;
    final liquidacion = capital + interesConDesc;

    String? error;
    if (pend.isEmpty) {
      error = 'No hay cuotas pendientes en el plan de pagos.';
    } else if (pend.length < minCuotasPendientes) {
      error =
          'Se requieren al menos $minCuotasPendientes cuotas pendientes '
          '(hay ${pend.length}).';
    }

    return ProntoPagoCalculo(
      cuotasPendientes: pend.length,
      capitalPendiente: capital,
      interesPendiente: interes,
      descuentoInteresPct: pct,
      descuentoSobreInteres: descuentoMonto,
      interesTrasDescuento: interesConDesc,
      montoLiquidacion: liquidacion,
      elegible: error == null,
      error: error,
    );
  }

  /// Serializa el acuerdo en observaciones (no modifica saldos contables).
  static String serializarAcuerdo({
    required ProntoPagoCalculo calc,
    required DateTime fecha,
    String? notas,
  }) {
    final line =
        '$markerPrefix${calc.capitalPendiente.toStringAsFixed(2)}|'
        '${calc.interesPendiente.toStringAsFixed(2)}|'
        '${calc.descuentoInteresPct.toStringAsFixed(2)}|'
        '${calc.montoLiquidacion.toStringAsFixed(2)}|'
        '${fecha.toIso8601String()}'
        '${notas != null && notas.isNotEmpty ? '|${notas.replaceAll('|', '/')}' : ''}';
    return line;
  }

  static ProntoPagoAcuerdo? parsearAcuerdo(String? observaciones) {
    if (observaciones == null || observaciones.isEmpty) return null;
    final line = observaciones
        .split('\n')
        .map((e) => e.trim())
        .firstWhere(
          (e) => e.startsWith(markerPrefix),
          orElse: () => '',
        );
    if (line.isEmpty) return null;
    final p = line.substring(markerPrefix.length).split('|');
    if (p.length < 4) return null;
    return ProntoPagoAcuerdo(
      capital: double.tryParse(p[0]) ?? 0,
      interes: double.tryParse(p[1]) ?? 0,
      descuentoPct: double.tryParse(p[2]) ?? 0,
      liquidacion: double.tryParse(p[3]) ?? 0,
      fechaIso: p.length > 4 ? p[4] : null,
      notas: p.length > 5 ? p.sublist(5).join('|') : null,
    );
  }

  /// Quita la línea del acuerdo; deja el resto de observaciones.
  static String quitarAcuerdo(String? observaciones) {
    if (observaciones == null || observaciones.isEmpty) return '';
    return observaciones
        .split('\n')
        .where((e) => !e.trim().startsWith(markerPrefix))
        .join('\n')
        .trim();
  }

  static String mergeObservaciones(String? actual, String acuerdoLine) {
    final base = quitarAcuerdo(actual);
    if (base.isEmpty) return acuerdoLine;
    return '$base\n$acuerdoLine';
  }
}

class ProntoPagoCalculo {
  const ProntoPagoCalculo({
    required this.cuotasPendientes,
    required this.capitalPendiente,
    required this.interesPendiente,
    required this.descuentoInteresPct,
    required this.descuentoSobreInteres,
    required this.interesTrasDescuento,
    required this.montoLiquidacion,
    required this.elegible,
    this.error,
  });

  final int cuotasPendientes;
  final double capitalPendiente;
  final double interesPendiente;
  final double descuentoInteresPct;
  final double descuentoSobreInteres;
  final double interesTrasDescuento;
  final double montoLiquidacion;
  final bool elegible;
  final String? error;
}

class ProntoPagoAcuerdo {
  const ProntoPagoAcuerdo({
    required this.capital,
    required this.interes,
    required this.descuentoPct,
    required this.liquidacion,
    this.fechaIso,
    this.notas,
  });

  final double capital;
  final double interes;
  final double descuentoPct;
  final double liquidacion;
  final String? fechaIso;
  final String? notas;
}
