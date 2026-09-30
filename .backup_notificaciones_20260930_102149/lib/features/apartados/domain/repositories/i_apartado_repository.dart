abstract class IApartadoRepository {
  Future<int> registrarApartado({
    required DateTime fecha,
    required int clienteId,
    required int usuarioId,
    required List<Map<String, dynamic>> productos,
    required double total,
    required double anticipo,
    required DateTime validoHasta,
  });

  Future<void> registrarAbono(int apartadoId, double monto);

  Future<int> convertirEnVenta(int apartadoId);

  Future<void> cancelarApartado(int apartadoId, String motivo);

  Future<List<Map<String, dynamic>>> listarApartados({
    DateTime? desde,
    DateTime? hasta,
    int? clienteId,
    int? usuarioId,
    String? estado,
  });

  Future<Map<String, dynamic>?> obtenerPorId(int apartadoId);
}
