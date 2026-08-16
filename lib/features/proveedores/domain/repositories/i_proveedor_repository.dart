/// Contrato abstracto para el repositorio de Proveedores.
///
/// Define operaciones disponibles sobre la entidad Proveedor,
/// sin exponer detalles de almacenamiento ni tecnología.
abstract class IProveedorRepository {
  /// Actualiza el saldo pendiente con un proveedor.
  /// [esAdeudo] = suma al saldo; [esPago] = resta del saldo.
  Future<void> actualizarSaldo(String proveedorId, double monto, bool esAdeudo);

  /// Obtiene el saldo actual con el proveedor.
  Future<double?> obtenerSaldo(String proveedorId);
}
