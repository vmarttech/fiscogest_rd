import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/features/inventario/domain/entities/producto.dart';
import 'package:fiscogest_rd/features/inventario/domain/entities/salida.dart';
import 'package:fiscogest_rd/features/inventario/domain/interfaces/i_producto_repository.dart';
import 'package:fiscogest_rd/features/inventario/domain/interfaces/i_salida_repository.dart';
import 'package:fiscogest_rd/features/inventario/domain/entities/kardex.dart';
import 'package:fiscogest_rd/features/inventario/domain/enums/tipo_movimiento.dart';
import 'package:fiscogest_rd/features/inventario/domain/interfaces/ikardex_repository.dart';

class OperacionesSalidaService {
  OperacionesSalidaService({
    required this.salidaRepository,
    required this.productoRepository,
    required this.kardexRepository,
    required this.db,
  });

  final ISalidaRepository salidaRepository;
  final IProductoRepository productoRepository;
  final IKardexRepository kardexRepository;
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

      final saldoAnterior = producto.stock ?? 0.0;
      final actualizado = descontarStock(producto, cantidad);
      await productoRepository.actualizarProducto(actualizado);

      final costo = (producto.costoPromedio > 0)
          ? producto.costoPromedio
          : (producto.precioCompra > 0 ? producto.precioCompra : 0.0);
      await kardexRepository.registrarMovimiento(
        Kardex(
          productoId: productoId,
          tipoMovimiento: TipoMovimiento.salida,
          cantidad: cantidad,
          saldoAnterior: saldoAnterior,
          saldoNuevo: actualizado.stock ?? saldoAnterior - cantidad,
          costoUnitario: costo,
          totalMovimiento: costo * cantidad,
          fechaMovimiento: DateTime.now(),
          documentoReferencia: 'Salida manual',
          observacion: motivo,
          usuarioId: 1,
        ),
      );
    });
  }
}
