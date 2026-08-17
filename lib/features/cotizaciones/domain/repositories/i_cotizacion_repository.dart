abstract class ICotizacionRepository {
  Future<int> registrarCotizacion({
    required DateTime fecha,
    required int clienteId,
    required int usuarioId,
    required List<Map<String, dynamic>> productos,
    required double subtotal,
    required double descuento,
    required double impuestos,
    required double total,
    required DateTime validoHasta,
  });

  Future<int> convertirEnVenta(int cotizacionId);

  Future<void> editarCotizacion({
    required int cotizacionId,
    List<Map<String, dynamic>>? productos,
    double? descuento,
    DateTime? validoHasta,
  });

  Future<List<Map<String, dynamic>>> listarCotizaciones({
    DateTime? desde,
    DateTime? hasta,
    int? clienteId,
    int? usuarioId,
  });

  Future<Map<String, dynamic>?> obtenerPorId(int cotizacionId);
}
