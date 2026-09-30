import 'package:fiscogest_rd/features/proveedores/domain/repositories/i_proveedor_repository.dart';

class ActualizarSaldoProveedor {
  ActualizarSaldoProveedor(this._repositorio);
  final IProveedorRepository _repositorio;

  Future<void> call({
    required int proveedorId,
    required double monto,
    required bool esAdeudo,
  }) async {
    final montoAplicar = esAdeudo ? monto : -monto;
    await _repositorio.registrarCompraProveedor(
      proveedorId: proveedorId,
      monto: montoAplicar,
    );
  }
}
