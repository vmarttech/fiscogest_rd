/// Contrato abstracto para el repositorio de Ventas.
///
/// Define operaciones disponibles sobre la entidad Venta,
/// sin exponer detalles de almacenamiento ni tecnología.
abstract class IVentaRepository {
  /// Registra una nueva venta con todos sus datos.
  Future<String> registrarVenta({
    required DateTime fecha,
    required String clienteId,
    required String usuarioId,
    required List<Map<String, dynamic>> productos,
    required double subtotal,
    required double descuento,
    required double impuestos,
    required double total,
  });

  /// Busca ventas aplicando filtros combinados.
  Future<List<Map<String, dynamic>>> listarVentas({
    DateTime? desde,
    DateTime? hasta,
    String? clienteId,
    String? usuarioId,
  });

  /// Obtiene una venta específica por su identificador.
  Future<Map<String, dynamic>?> obtenerPorId(String ventaId);
}
