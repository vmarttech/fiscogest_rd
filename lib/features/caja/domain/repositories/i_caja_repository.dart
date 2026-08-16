/// Contrato abstracto para el repositorio de Caja.
///
/// Define operaciones de registro y consulta de movimientos de caja,
/// sin exponer detalles de almacenamiento ni tecnología.
abstract class ICajaRepository {
  /// Registra un movimiento de caja (ingreso o egreso).
  Future<void> registrarMovimiento({
    required String referencia,
    required double monto,
    required String tipo,
    required String descripcion,
  });

  /// Obtiene el saldo actual de caja.
  Future<double?> obtenerSaldoActual();
}
