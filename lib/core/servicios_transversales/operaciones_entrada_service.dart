import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/features/inventario/domain/entities/entrada.dart';
import 'package:fiscogest_rd/features/inventario/domain/entities/producto.dart';
import 'package:fiscogest_rd/features/inventario/domain/interfaces/i_entrada_repository.dart';
import 'package:fiscogest_rd/features/inventario/domain/interfaces/i_producto_repository.dart';

class OperacionesEntradaService {
  OperacionesEntradaService({
    required this.entradaRepository,
    required this.productoRepository,
    required this.db,
  });

  final IEntradaRepository entradaRepository;
  final IProductoRepository productoRepository;
  final AppDatabase db;

  Producto aumentarStock(Producto producto, double cantidad) {
    final double stockActual = producto.stock ?? 0.0;
    final double nuevoStock = stockActual + cantidad;
    return producto.copyWith(stock: nuevoStock);
  }

  Future<void> registrarEntradaConAjusteStock({
    required int productoId,
    required double cantidad,
    required String motivo,
    required String usuario,
  }) async {
    await db.transaction(() async {
      await entradaRepository.registrarEntrada(Entrada(
        productoId: productoId,
        cantidad: cantidad,
        motivo: motivo,
        usuario: usuario,
        fecha: DateTime.now(),
      ));

      final producto = await productoRepository.obtenerProductoPorId(productoId);
      if (producto != null) {
        final actualizado = aumentarStock(producto, cantidad);
        await productoRepository.actualizarProducto(actualizado);
      }
    });
  }
}
