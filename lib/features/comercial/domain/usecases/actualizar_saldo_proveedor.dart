import 'package:fiscogest_rd/features/proveedores/domain/repositories/i_proveedor_repository.dart';

class ActualizarSaldoProveedor {
  ActualizarSaldoProveedor(this._repositorio);
  final IProveedorRepository _repositorio;

  Future<void> call({
    required String proveedorId,
    required double monto,
    required bool esAdeudo,
  }) async {
    await _repositorio.actualizarSaldo(proveedorId, monto, esAdeudo);
  }
}
