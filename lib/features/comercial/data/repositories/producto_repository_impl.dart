import 'package:fiscogest_rd/features/comercial/domain/repositories/i_producto_repository.dart';

class ProductoRepositoryImpl implements IProductoRepository {
  final _costos = <String, Map<String, double>>{};

  @override
  Future<void> actualizarCostoProducto({
    required String productoId,
    required double costoUnitario,
    required double cantidadAnterior,
    required double cantidadMovimiento,
  }) async {
    _costos[productoId] = {
      'costoUnitario': costoUnitario,
      'cantidadAnterior': cantidadAnterior,
      'cantidadMovimiento': cantidadMovimiento,
    };
  }
}
