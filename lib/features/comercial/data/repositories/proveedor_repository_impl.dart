import 'package:fiscogest_rd/features/proveedores/domain/repositories/i_proveedor_repository.dart';

class ProveedorRepositoryImpl implements IProveedorRepository {
  final _saldos = <int, double>{};

  @override
  Future<void> registrarCompraProveedor({
    required int proveedorId,
    required double monto,
  }) async {
    _saldos[proveedorId] = (_saldos[proveedorId] ?? 0) + monto;
  }
}
