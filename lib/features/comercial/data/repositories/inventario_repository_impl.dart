import 'package:fiscogest_rd/features/comercial/domain/repositories/i_inventario_repository.dart';

class InventarioRepositoryImpl implements IInventarioRepository {
  final _existencias = <String, double>{};

  @override
  Future<void> aumentarExistencias({
    required String productoId,
    required double cantidad,
  }) async {
    _existencias[productoId] = (_existencias[productoId] ?? 0) + cantidad;
  }

  @override
  Future<void> descontarExistencias({
    required String productoId,
    required double cantidad,
  }) async {
    final actual = _existencias[productoId] ?? 0;
    if (actual < cantidad) {
      throw StateError('Existencias insuficientes para producto: $productoId');
    }
    _existencias[productoId] = actual - cantidad;
  }
}
