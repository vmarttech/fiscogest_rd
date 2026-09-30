import 'package:fiscogest_rd/features/proveedores/domain/entities/proveedor.dart';

abstract class IProveedorRepository {
  Future<List<Proveedor>> obtenerProveedores();
  Future<Proveedor?> obtenerProveedorPorId(int id);
  Future<int> guardarProveedor(Proveedor proveedor);
  Future<bool> actualizarProveedor(Proveedor proveedor);
  Future<bool> eliminarProveedor(int id);

  /// Registra compra en historial y saldo del proveedor — compatibilidad
  Future<void> registrarCompraProveedor({
    required int proveedorId,
    required double monto,
  });

  /// Agrega monto al saldo pendiente
  Future<void> agregarSaldo(int proveedorId, double monto);

  /// Consulta saldo actual
  Future<double> obtenerSaldo(int proveedorId);
}
