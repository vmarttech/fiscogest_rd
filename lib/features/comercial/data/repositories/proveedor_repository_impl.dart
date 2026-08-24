import 'package:fiscogest_rd/features/comercial/domain/repositories/i_proveedor_repository.dart';

class ProveedorRepositoryImpl implements IProveedorRepository {
  final _saldos = <String, double>{};

  @override
  Future<void> registrarCompraProveedor({
    required String proveedorId,
    required double monto,
  }) async {
    _saldos[proveedorId] = (_saldos[proveedorId] ?? 0) + monto;
  }
}
