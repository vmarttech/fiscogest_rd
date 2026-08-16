/// Contrato abstracto para el repositorio de Cotizaciones.
///
/// Define operaciones disponibles sobre la entidad Cotización,
/// sin exponer detalles de almacenamiento ni tecnología.
abstract class ICotizacionRepository {
  /// Registra una nueva cotización.
  Future<String> registrarCotizacion({
    required DateTime fecha,
    required String clienteId,
    required String usuarioId,
    required List<Map<String, dynamic>> productos,
    required double subtotal,
    required double descuento,
    required double impuestos,
    required double total,
    required DateTime validoHasta,
  });

  /// Convierte una cotización existente en una venta.
  Future<String> convertirEnVenta(String cotizacionId);

  /// Actualiza datos de una cotización existente.
  Future<void> editarCotizacion({
    required String cotizacionId,
    List<Map<String, dynamic>>? productos,
    double? descuento,
    DateTime? validoHasta,
  });

  /// Busca cotizaciones aplicando filtros combinados.
  Future<List<Map<String, dynamic>>> listarCotizaciones({
    DateTime? desde,
    DateTime? hasta,
    String? clienteId,
    String? usuarioId,
  });

  /// Obtiene una cotización específica por su identificador.
  Future<Map<String, dynamic>?> obtenerPorId(String cotizacionId);
}
