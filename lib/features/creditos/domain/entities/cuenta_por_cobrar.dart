import 'package:fiscogest_rd/features/creditos/domain/entities/estado_credito.dart';
import 'package:fiscogest_rd/features/creditos/domain/entities/plan_pago.dart';
import 'package:fiscogest_rd/features/creditos/domain/entities/abono_credito.dart';
import 'package:fiscogest_rd/features/creditos/domain/entities/cuota.dart';

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
    this.moraCalculada = 0.0,
    this.diasVencidoActual = 0,
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

  /// Mora pendiente del ledger, más la acumulación desde el último corte.
  final double moraCalculada;

  /// Días transcurridos desde la fecha de vencimiento al momento de leer.
  final int diasVencidoActual;

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

  /// Capital e intereses que quedan pendientes en el cronograma.
  double get saldoCuotasPendiente {
    final cuotas = planPago?.cuotas;
    if (cuotas != null && cuotas.isNotEmpty) {
      return cuotas.fold<double>(
        0,
        (sum, cuota) => sum + saldoPendienteCuota(cuota),
      );
    }
    return (totalAPagar -
            abonos.fold<double>(0, (sum, abono) => sum + abono.monto))
        .clamp(0.0, double.infinity);
  }

  /// Total listo para cobrar: cuotas pendientes más mora ya calculada.
  double get saldoPendiente =>
      (saldoCuotasPendiente + moraCalculada).clamp(0.0, double.infinity);

  /// Saldo exigible ahora: principal pendiente + mora calculada.
  double get totalConMora => double.parse(saldoPendiente.toStringAsFixed(2));

  /// Si ya está totalmente pagada
  bool get estaPagada {
    return totalConMora <= 0.001;
  }

  /// Próxima fecha de pago según la cuota pendiente más cercana.
  DateTime get fechaProximoVencimiento {
    final pendientes = planPago?.cuotas
        .where((q) => !q.pagada && saldoPendienteCuota(q) > 0.001)
        .toList();
    if (pendientes == null || pendientes.isEmpty) return fechaVencimiento;
    pendientes.sort((a, b) => a.fechaVencimiento.compareTo(b.fechaVencimiento));
    return pendientes.first.fechaVencimiento;
  }

  double saldoPendienteCuota(Cuota cuota) {
    if (cuota.pagada) return 0;
    final saldo = cuota.saldoCuotaPendiente;
    return (saldo ?? cuota.montoTotal).clamp(0.0, double.infinity);
  }

  /// Saldo de las cuotas ya vencidas, separado del principal futuro.
  double saldoCuotasVencidas({DateTime? hoy}) {
    if (estaPagada) return 0;
    final cuotas = planPago?.cuotas;
    if (cuotas == null || cuotas.isEmpty) {
      return diasVencido(hoy ?? DateTime.now()) > 0 ? saldoPendiente : 0;
    }
    return cuotas.fold<double>(0, (sum, cuota) {
      if (diasAtrasoCuota(cuota, hoy: hoy) == 0) return sum;
      return sum + saldoPendienteCuota(cuota);
    });
  }

  int diasAtrasoCuota(Cuota cuota, {DateTime? hoy}) {
    if (saldoPendienteCuota(cuota) <= 0.001) return 0;
    final fecha = _dia(cuota.fechaVencimiento);
    final actual = _dia(hoy ?? DateTime.now());
    return actual.isAfter(fecha) ? actual.difference(fecha).inDays : 0;
  }

  double moraEstimadaCuota(
    Cuota cuota, {
    required double moraMensual,
    DateTime? hoy,
  }) {
    if (cuota.moraPendiente != null) return cuota.moraPendiente!;
    final dias = diasAtrasoCuota(cuota, hoy: hoy);
    final saldo = saldoPendienteCuota(cuota);
    if (dias == 0 || saldo <= 0.001 || moraMensual <= 0) return 0;
    final mora = saldo * (moraMensual / 30) * dias;
    return double.parse(mora.toStringAsFixed(2));
  }

  EstadoCredito estadoActual({DateTime? hoy}) {
    if (estaPagada) return EstadoCredito.pagado;
    final actual = _dia(hoy ?? DateTime.now());
    final cuotas = planPago?.cuotas;
    if (cuotas != null && cuotas.isNotEmpty) {
      final pendientes =
          cuotas.where((q) => saldoPendienteCuota(q) > 0.001).toList()
            ..sort((a, b) => a.fechaVencimiento.compareTo(b.fechaVencimiento));
      if (pendientes.any((q) => diasAtrasoCuota(q, hoy: actual) > 0)) {
        return EstadoCredito.vencido;
      }
      if (pendientes.isNotEmpty) {
        final diasHasta = _dia(
          pendientes.first.fechaVencimiento,
        ).difference(actual).inDays;
        if (diasHasta <= 3) return EstadoCredito.proximoAVencer;
      }
      return EstadoCredito.alDia;
    }

    final dias = actual.difference(_dia(fechaVencimiento)).inDays;
    if (dias > 0) return EstadoCredito.vencido;
    if (dias >= -3) return EstadoCredito.proximoAVencer;
    return EstadoCredito.alDia;
  }

  /// Días de atraso (negativo = al día, positivo = vencido)
  int diasVencido(DateTime hoy) {
    if (estaPagada) return 0;
    final cuotas = planPago?.cuotas;
    if (cuotas != null && cuotas.isNotEmpty) {
      return cuotas
          .map((q) => diasAtrasoCuota(q, hoy: hoy))
          .fold<int>(0, (maximo, dias) => dias > maximo ? dias : maximo);
    }
    final dias = _dia(hoy).difference(_dia(fechaVencimiento)).inDays;
    return dias > 0 ? dias : 0;
  }

  /// Mora vigente calculada por cuota con la tasa mensual configurada / 30.
  double moraEstimada({required double moraMensual, DateTime? hoy}) {
    if (moraCalculada > 0.001) return moraCalculada;
    if (saldoPendiente <= 0.001 || moraMensual <= 0) return 0;
    final cuotas = planPago?.cuotas;
    if (cuotas != null && cuotas.isNotEmpty) {
      final total = cuotas.fold<double>(
        0,
        (sum, q) =>
            sum + moraEstimadaCuota(q, moraMensual: moraMensual, hoy: hoy),
      );
      return double.parse(total.toStringAsFixed(2));
    }
    final dias = diasVencido(hoy ?? DateTime.now());
    if (dias == 0) return 0;
    final monto = saldoPendiente * (moraMensual / 30.0) * dias;
    return double.parse(monto.toStringAsFixed(2));
  }

  DateTime _dia(DateTime fecha) => DateTime(fecha.year, fecha.month, fecha.day);

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
    double? moraCalculada,
    int? diasVencidoActual,
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
      moraCalculada: moraCalculada ?? this.moraCalculada,
      diasVencidoActual: diasVencidoActual ?? this.diasVencidoActual,
    );
  }
}
