import 'package:fiscogest_rd/features/creditos/domain/entities/estado_credito.dart';
import 'package:fiscogest_rd/features/creditos/domain/entities/plan_pago.dart';
import 'package:fiscogest_rd/features/creditos/domain/entities/abono_credito.dart';

/// Cuenta por cobrar generada al registrar una venta a crédito / fiao
/// Según manual sección 5: todos los campos requeridos
class CuentaPorCobrar {
  const CuentaPorCobrar({
    this.id,
    this.numero,
    required this.clienteId,
    this.clienteNombre,
    this.ventaId,
    required this.totalOriginal,
    this.abonoInicial = 0.0,
    this.tasaInteres = 0.0,
    this.montoInteres = 0.0,
    this.plazoDias = 30,
    this.numeroCuotas = 1,
    this.planPago,
    this.abonos = const [],
    required this.fechaCreacion,
    required this.fechaVencimiento,
    this.estado = EstadoCredito.alDia,
    this.observaciones,
    this.usuarioId,
  });

  final int? id;

  /// Número legible de cuenta (ej: "CXC-000124")
  final String? numero;

  final int clienteId;
  final String? clienteNombre;

  /// Venta que originó esta cuenta (si viene del flujo de ventas)
  final int? ventaId;

  /// Monto total de la venta original
  final double totalOriginal;

  /// Pago inicial al momento de firmar el crédito
  final double abonoInicial;

  /// Tasa de interés aplicada (OCULTA al cliente)
  final double tasaInteres;

  /// Monto total de intereses (SÍ se muestra al cliente)
  final double montoInteres;

  /// Plazo pactado en días
  final int plazoDias;

  /// Cantidad de cuotas pactadas
  final int numeroCuotas;

  /// Plan estructurado de cuotas (opcional, si es pago único queda null)
  final PlanPago? planPago;

  /// Historial de abonos realizados
  final List<AbonoCredito> abonos;

  final DateTime fechaCreacion;
  final DateTime fechaVencimiento;
  final EstadoCredito estado;
  final String? observaciones;
  final int? usuarioId;

  // ============================================
  // CAMPOS CALCULADOS
  // ============================================

  /// Monto que realmente se financia: total − abono inicial
  double get saldoFinanciado {
    return (totalOriginal - abonoInicial).clamp(0.0, double.infinity);
  }

  /// Monto total que debe pagar el cliente: saldo financiado + intereses
  double get totalAPagar {
    return saldoFinanciado + montoInteres;
  }

  /// Suma de todos los abonos realizados
  double get totalAbonado {
    return abonos.fold<double>(0.0, (sum, a) => sum + a.monto);
  }

  /// Cuánto le falta pagar
  double get saldoPendiente {
    return (totalAPagar - totalAbonado).clamp(0.0, double.infinity);
  }

  /// Si ya está totalmente pagada
  bool get estaPagada {
    return saldoPendiente <= 0.001;
  }

  /// Días de atraso (negativo = al día, positivo = vencido)
  int diasVencido(DateTime hoy) {
    if (estaPagada) return 0;
    return hoy.difference(fechaVencimiento).inDays;
  }

  CuentaPorCobrar copyWith({
    int? id,
    String? numero,
    int? clienteId,
    String? clienteNombre,
    int? ventaId,
    double? totalOriginal,
    double? abonoInicial,
    double? tasaInteres,
    double? montoInteres,
    int? plazoDias,
    int? numeroCuotas,
    PlanPago? planPago,
    List<AbonoCredito>? abonos,
    DateTime? fechaCreacion,
    DateTime? fechaVencimiento,
    EstadoCredito? estado,
    String? observaciones,
    int? usuarioId,
  }) {
    return CuentaPorCobrar(
      id: id ?? this.id,
      numero: numero ?? this.numero,
      clienteId: clienteId ?? this.clienteId,
      clienteNombre: clienteNombre ?? this.clienteNombre,
      ventaId: ventaId ?? this.ventaId,
      totalOriginal: totalOriginal ?? this.totalOriginal,
      abonoInicial: abonoInicial ?? this.abonoInicial,
      tasaInteres: tasaInteres ?? this.tasaInteres,
      montoInteres: montoInteres ?? this.montoInteres,
      plazoDias: plazoDias ?? this.plazoDias,
      numeroCuotas: numeroCuotas ?? this.numeroCuotas,
      planPago: planPago ?? this.planPago,
      abonos: abonos ?? this.abonos,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      fechaVencimiento: fechaVencimiento ?? this.fechaVencimiento,
      estado: estado ?? this.estado,
      observaciones: observaciones ?? this.observaciones,
      usuarioId: usuarioId ?? this.usuarioId,
    );
  }
}
