abstract class ICajaRepository {
  Future<void> registrarMovimiento({
    required String referencia,
    required double monto,
    required String tipo,
    required String descripcion,
    String formaPago = 'efectivo',
  });
  Future<double?> obtenerSaldoActual();
}
