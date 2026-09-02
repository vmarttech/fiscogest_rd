import 'package:fiscogest_rd/features/comercial/domain/repositories/i_inventario_repository.dart';

class InventarioRepositoryImpl implements IInventarioRepository {
  final _existencias = <int, double>{};
  @override
  Future<void> aumentarExistencias({
    required int productoId,
    required double cantidad,
  }) async {
    _existencias[productoId] = (_existencias[productoId] ?? 0) + cantidad;
  }

  @override
  Future<void> descontarExistencias({
    required int productoId,
    required double cantidad,
  }) async {
    final actual = _existencias[productoId] ?? 0;
    if (actual < cantidad) {
      throw StateError('Existencias insuficientes para producto: $productoId');
    }
    _existencias[productoId] = actual - cantidad;
  }
}
