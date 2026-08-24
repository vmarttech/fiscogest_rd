/// Contrato abstracto para actualización de saldos de proveedores.
abstract class IProveedorRepository {
  /// Registra el monto de compra en el saldo y historial del proveedor.
  Future<void> registrarCompraProveedor({
    required String proveedorId,
    required double monto,
  });
}
