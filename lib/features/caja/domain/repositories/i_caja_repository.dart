abstract class ICajaRepository {
  /// Registra movimiento en la sesión ABIERTA (obligatorio).
  Future<void> registrarMovimiento({
    required String referencia,
    required double monto,
    required String tipo, // ingreso | egreso
    required String descripcion,
    String formaPago = 'efectivo',
  });

  /// Efectivo esperado del cajón en la sesión abierta
  /// (fondo + ingresos efectivo − egresos efectivo). Null si no hay sesión.
  Future<double?> obtenerSaldoActual();

  Future<CajaSesionResumen?> obtenerSesionAbierta();

  Future<int> abrirSesion({required double fondoInicial, int usuarioId = 1});

  /// Resumen de cuadre de una sesión (abierta o cerrada).
  Future<ResumenSesionCaja> obtenerResumenSesion(int sesionId);

  Future<List<CajaMovimientoResumen>> listarMovimientosPorSesion(int sesionId);

  /// Legado: por fecha (puede mezclar turnos). Preferir [listarMovimientosPorSesion].
  Future<List<CajaMovimientoResumen>> listarMovimientosDesde(DateTime desde);

  /// Cierra la sesión. [saldoTeorico] se recalcula en repo como efectivo de sesión
  /// si se pasa null/ignora; la UI puede enviar el del resumen.
  Future<bool> cerrarSesion({
    required int sesionId,
    required double saldoTeorico,
    required double montoContado,
    String? observacion,
  });
}

class CajaSesionResumen {
  const CajaSesionResumen({
    required this.id,
    required this.fechaApertura,
    required this.fondoInicial,
    required this.usuarioId,
    required this.estado,
  });

  final int id;
  final DateTime fechaApertura;
  final double fondoInicial;
  final int usuarioId;
  final String estado;

  bool get estaAbierta => estado == 'abierta';
}

class CajaMovimientoResumen {
  const CajaMovimientoResumen({
    required this.id,
    required this.tipo,
    required this.monto,
    required this.formaPago,
    required this.saldoNuevo,
    required this.fecha,
    required this.referenciaTipo,
    required this.referenciaId,
    this.sesionId,
  });

  final int id;
  final String tipo;
  final double monto;
  final String formaPago;
  final double saldoNuevo;
  final DateTime fecha;
  final String referenciaTipo;
  final int referenciaId;
  final int? sesionId;
}

/// Desglose para el cajero: solo el efectivo se cuenta en el cajón.
class ResumenSesionCaja {
  const ResumenSesionCaja({
    required this.sesionId,
    required this.fondoInicial,
    required this.ingresosEfectivo,
    required this.egresosEfectivo,
    required this.efectivoEsperado,
    required this.ingresosTarjeta,
    required this.ingresosTransferencia,
    required this.ingresosCheque,
    required this.ingresosCredito,
    required this.totalIngresos,
    required this.totalEgresos,
  });

  final int sesionId;
  final double fondoInicial;
  final double ingresosEfectivo;
  final double egresosEfectivo;
  final double efectivoEsperado;
  final double ingresosTarjeta;
  final double ingresosTransferencia;
  final double ingresosCheque;
  final double ingresosCredito;
  final double totalIngresos;
  final double totalEgresos;
}
