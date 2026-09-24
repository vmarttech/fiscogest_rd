abstract class ICajaRepository {
  Future<void> registrarMovimiento({
    required String referencia,
    required double monto,
    required String tipo,
    required String descripcion,
    String formaPago = 'efectivo',
  });

  Future<double?> obtenerSaldoActual();

  /// Sesión abierta actual, o null si la caja está cerrada.
  Future<CajaSesionResumen?> obtenerSesionAbierta();

  Future<int> abrirSesion({
    required double fondoInicial,
    int usuarioId = 1,
  });

  /// Movimientos desde [desde] (apertura del turno) hasta ahora.
  Future<List<CajaMovimientoResumen>> listarMovimientosDesde(DateTime desde);

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
  });

  final int id;
  final String tipo;
  final double monto;
  final String formaPago;
  final double saldoNuevo;
  final DateTime fecha;
  final String referenciaTipo;
  final int referenciaId;
}
