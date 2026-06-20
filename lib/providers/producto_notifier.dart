import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogestrd/models/producto.dart';
import 'package:fiscogestrd/repositories/producto_repository.dart';

class ProductoNotifier extends StateNotifier<List<Producto>> {
  ProductoNotifier(this._repository) : super([]) {
    _cargarDatos();
  }
  final ProductoRepository _repository;

  Future<void> _cargarDatos() async {
    try {
      final lista = await _repository.obtenerTodosActivos();
      state = lista;
    } catch (e) {
      state = [];
    }
  }

  Future<void> cargarDatos() async {
    await _cargarDatos();
  }

  // ✅ AGREGADO: Método que faltaba para que funcione en las pantallas
  Future<void> cargarTodos() async {
    await cargarDatos();
  }

  Future<void> guardar(Producto producto) async {
    try {
      await _repository.guardar(producto);
      await cargarDatos();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> borrar(int id) async {
    try {
      await _repository.eliminarFisico(id);
      await cargarDatos();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> asignarRegimenAFactura(
    Producto producto,
    Map<String, dynamic> regimen,
  ) async {
    final actualizado = producto.copyWith(
      porcentajeImpuesto: regimen['tasa'],
      aplicaImpuesto: regimen['aplicaImpuesto'],
      categoria: regimen['nombre'].split('(')[0].trim(),
      regimenImpuesto: regimen['nombre'],
      esImpuestoSelectivo: regimen['esSelectivo'],
    );
    await guardar(actualizado);
  }

  Future<void> buscar(String query) async {
    try {
      final resultados = await _repository.buscar(query);
      state = resultados;
    } catch (e) {
      state = [];
    }
  }

  Future<void> actualizarStock(int id, dynamic cantidad) async {
    try {
      await _repository.actualizarNivelStock(id, (cantidad as num).toDouble());
      await cargarDatos();
    } catch (e) {
      rethrow;
    }
  }

  // ✅ MÉTODOS AGREGADOS PARA COMPRAS Y VENTAS
  /// Aumenta el stock al registrar una compra
  Future<void> aumentarStock(int productoId, dynamic cantidad) async {
    try {
      await _repository.aumentarStock(productoId, cantidad);
      await cargarDatos(); // Refresca la lista en pantalla
    } catch (e) {
      rethrow;
    }
  }

  /// Descuenta el stock al registrar una venta
  /// Devuelve `true` si hay suficiente inventario, `false` si no
  Future<bool> descontarStock(int productoId, dynamic cantidad) async {
    try {
      final exito = await _repository.descontarStock(productoId, cantidad);
      if (exito) await cargarDatos(); // Solo refresca si se descontó
      return exito;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> cargarTodosSinFiltro() async {
    try {
      final lista = await _repository.obtenerTodos();
      state = lista;
    } catch (e) {
      state = [];
    }
  }
}

final productoRepositoryProvider = Provider((ref) => ProductoRepository());

final productoNotifierProvider =
    StateNotifierProvider<ProductoNotifier, List<Producto>>((ref) {
      final repo = ref.watch(productoRepositoryProvider);
      return ProductoNotifier(repo);
    });