import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/core/database/database_provider.dart';

final productoProvider =
    StateNotifierProvider<ProductoNotifier, List<ProductoData>>((ref) {
      return ProductoNotifier(ref);
    });

class ProductoNotifier extends StateNotifier<List<ProductoData>> {
  ProductoNotifier(Ref ref) : _db = ref.read(databaseProvider), super([]) {
    cargarTodos();
  }

  final AppDatabase _db;

  Future<void> cargarTodos() async {
    state = await _db.select(_db.productosTable).get();
  }

  Future<ProductoData?> buscarPorId(int productoId) async {
    return await (_db.select(
      _db.productosTable,
    )..where((p) => p.id.equals(productoId))).getSingleOrNull();
  }

  Future<void> reservarStock(int productoId, double cantidad) async {
    final reg = await buscarPorId(productoId);
    if (reg == null) throw Exception('Producto no encontrado');
    final stockActual = reg.stock ?? 0.0;
    final reservado = reg.stockReservado ?? 0.0;
    final disponible = stockActual - reservado;
    if (disponible < cantidad) {
      throw Exception('Stock insuficiente para reservar');
    }
    await _db
        .update(_db.productosTable)
        .replace(reg.copyWith(stockReservado: Value(reservado + cantidad)));
    await cargarTodos();
  }

  Future<void> liberarStockReservado(int productoId, double cantidad) async {
    final reg = await buscarPorId(productoId);
    if (reg == null) throw Exception('Producto no encontrado');
    final reservado = reg.stockReservado ?? 0.0;
    double nuevaReservada = reservado - cantidad;
    if (nuevaReservada < 0) nuevaReservada = 0.0;
    await _db
        .update(_db.productosTable)
        .replace(reg.copyWith(stockReservado: Value(nuevaReservada)));
    await cargarTodos();
  }
}
