import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/features/inventario/domain/entities/producto.dart';
import 'package:fiscogest_rd/features/inventario/domain/entities/salida.dart';
import 'package:fiscogest_rd/features/inventario/domain/interfaces/i_producto_repository.dart';
import 'package:fiscogest_rd/features/inventario/domain/interfaces/i_salida_repository.dart';

class OperacionesSalidaService {
  OperacionesSalidaService({
    required this.salidaRepository,
    required this.productoRepository,
    required this.db,
  });

  final ISalidaRepository salidaRepository;
  final IProductoRepository productoRepository;
  final AppDatabase db;

  bool puedeDescontar(Producto producto, double cantidad) {
    final double stockActual = producto.stock ?? 0.0;
    return stockActual >= cantidad;
  }

  Producto descontarStock(Producto producto, double cantidad) {
    final double stockActual = producto.stock ?? 0.0;
    final double nuevoStock = stockActual - cantidad;
    return producto.copyWith(stock: nuevoStock);
  }

  Future<void> registrarSalidaConValidacionStock({
    required int productoId,
    required double cantidad,
    required String motivo,
    required String usuario,
  }) async {
    await db.transaction(() async {
      final producto = await productoRepository.obtenerProductoPorId(
        productoId,
      );
      if (producto == null) throw Exception('Producto no encontrado');
      if (!puedeDescontar(producto, cantidad)) {
        throw Exception('Stock insuficiente para realizar la salida');
      }

      await salidaRepository.registrarSalida(
        Salida(
          productoId: productoId,
          cantidad: cantidad,
          motivo: motivo,
          usuario: usuario,
          fecha: DateTime.now(),
        ),
      );

      final actualizado = descontarStock(producto, cantidad);
      await productoRepository.actualizarProducto(actualizado);
    });
  }
}
