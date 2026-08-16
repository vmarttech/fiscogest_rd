/// Contrato abstracto para el repositorio de Devoluciones.
///
/// Define operaciones disponibles sobre la entidad Devolución,
/// sin exponer detalles de almacenamiento ni tecnología.
abstract class IDevolucionRepository {
  /// Registra una devolución de productos (parcial o total).
  Future<String> registrarDevolucion({
    required DateTime fecha,
    required String tipoOrigen,
    required String origenId,
    required String clienteId,
    required String proveedorId,
    required String usuarioId,
    required List<Map<String, dynamic>> productos,
    required double montoDevuelto,
    required String motivo,
    required bool esTotal,
  });

  /// Busca devoluciones aplicando filtros combinados.
  Future<List<Map<String, dynamic>>> listarDevoluciones({
    DateTime? desde,
    DateTime? hasta,
    String? clienteId,
    String? proveedorId,
    String? usuarioId,
    String? tipoOrigen,
  });

  /// Obtiene una devolución específica por su identificador.
  Future<Map<String, dynamic>?> obtenerPorId(String devolucionId);
}
