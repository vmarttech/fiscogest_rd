/// Contrato abstracto para el repositorio de Apartados.
///
/// Define operaciones disponibles sobre la entidad Apartado,
/// sin exponer detalles de almacenamiento ni tecnología.
abstract class IApartadoRepository {
  /// Registra un nuevo apartado con productos y montos.
  Future<String> registrarApartado({
    required DateTime fecha,
    required String clienteId,
    required String usuarioId,
    required List<Map<String, dynamic>> productos,
    required double total,
    required double anticipo,
    required DateTime validoHasta,
  });

  /// Registra un pago o abono al saldo pendiente del apartado.
  Future<void> registrarAbono(String apartadoId, double monto);

  /// Convierte un apartado completado en una venta.
  Future<String> convertirEnVenta(String apartadoId);

  /// Cancela un apartado y libera los productos reservados.
  Future<void> cancelarApartado(String apartadoId, String motivo);

  /// Busca apartados aplicando filtros combinados.
  Future<List<Map<String, dynamic>>> listarApartados({
    DateTime? desde,
    DateTime? hasta,
    String? clienteId,
    String? usuarioId,
    String? estado,
  });

  /// Obtiene un apartado específico por su identificador.
  Future<Map<String, dynamic>?> obtenerPorId(String apartadoId);
}
