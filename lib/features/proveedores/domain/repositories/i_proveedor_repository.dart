/// Contrato abstracto para actualización de saldos de proveedores.
///
/// Define operaciones disponibles sobre la entidad Proveedor,
/// sin exponer detalles de almacenamiento ni tecnología.
abstract class IProveedorRepository {
  /// Registra el monto de compra en el saldo y historial del proveedor.
  Future<void> registrarCompraProveedor({
    required int proveedorId,
    required double monto,
  });
}
