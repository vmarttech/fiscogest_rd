/// Contrato abstracto para el repositorio de Clientes.
///
/// Define operaciones disponibles sobre la entidad Cliente,
/// sin exponer detalles de almacenamiento ni tecnología.
abstract class IClienteRepository {
  /// Actualiza el saldo pendiente de un cliente.
  /// [esCargo] = suma al saldo; [esAbono] = resta del saldo.
  Future<void> actualizarSaldo(String clienteId, double monto, bool esCargo);

  /// Obtiene el saldo actual del cliente.
  Future<double?> obtenerSaldo(String clienteId);
}
