import 'package:fiscogest_rd/features/creditos/domain/entities/cuota.dart';

/// Plan de pagos estructurado con cuotas e intereses
/// La tasa de interés NO se muestra al cliente, pero sí el monto resultante
class PlanPago {
  const PlanPago({
    this.id,
    required this.tasaInteresMensual,
    required this.numeroCuotas,
    required this.montoPorCuota,
    required this.fechaPrimerVencimiento,
    required this.cuotas,
  });

  final int? id;

  /// Tasa mensual (ej: 0.05 = 5%) — CAMPO OCULTO al cliente
  final double tasaInteresMensual;

  /// Cantidad total de cuotas
  final int numeroCuotas;

  /// Monto fijo de cada cuota (sistema francés)
  final double montoPorCuota;

  /// Fecha de vencimiento de la primera cuota
  final DateTime fechaPrimerVencimiento;

  /// Lista detallada de cada cuota
  final List<Cuota> cuotas;

  double get totalIntereses {
    return cuotas.fold<double>(0.0, (sum, c) => sum + c.montoInteres);
  }

  double get totalAPagar {
    return cuotas.fold<double>(0.0, (sum, c) => sum + c.montoTotal);
  }

  PlanPago copyWith({
    int? id,
    double? tasaInteresMensual,
    int? numeroCuotas,
    double? montoPorCuota,
    DateTime? fechaPrimerVencimiento,
    List<Cuota>? cuotas,
  }) {
    return PlanPago(
      id: id ?? this.id,
      tasaInteresMensual: tasaInteresMensual ?? this.tasaInteresMensual,
      numeroCuotas: numeroCuotas ?? this.numeroCuotas,
      montoPorCuota: montoPorCuota ?? this.montoPorCuota,
      fechaPrimerVencimiento:
          fechaPrimerVencimiento ?? this.fechaPrimerVencimiento,
      cuotas: cuotas ?? this.cuotas,
    );
  }
}
