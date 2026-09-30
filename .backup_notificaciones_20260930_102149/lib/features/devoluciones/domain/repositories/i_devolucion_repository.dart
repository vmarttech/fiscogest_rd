abstract class IDevolucionRepository {
  Future<int> registrarDevolucion({
    required DateTime fecha,
    required String tipoOrigen,
    required int origenId,
    required int clienteId,
    required int proveedorId,
    required int usuarioId,
    required List<Map<String, dynamic>> productos,
    required double montoDevuelto,
    required String motivo,
    required bool esTotal,
  });

  Future<List<Map<String, dynamic>>> listarDevoluciones({
    DateTime? desde,
    DateTime? hasta,
    int? clienteId,
    int? proveedorId,
    int? usuarioId,
    String? tipoOrigen,
  });

  Future<Map<String, dynamic>?> obtenerPorId(int devolucionId);
}
