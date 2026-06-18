import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/producto.dart';
import '../repositories/producto_repository.dart';

class ProductoNotifier extends StateNotifier<List<Producto>> {
  final ProductoRepository _repository;

  ProductoNotifier(this._repository) : super([]) {
    _cargarDatos(); // ✅ Llamada interna, correcta
  }

  // ✅ Método PRIVADO (solo dentro de esta clase) - TU LÓGICA ORIGINAL
  Future<void> _cargarDatos() async {
    try {
      final lista = await _repository.obtenerTodosActivos();
      state = lista;
    } catch (e) {
      state = [];
    }
  }

  // ✅ SOLUCIÓN: MÉTODO PÚBLICO PARA LLAMAR DESDE LA UI
  Future<void> cargarDatos() async {
    await _cargarDatos();
  }

  // ✅ RESTO DE TU LÓGICA, SIN CAMBIOS NI MEZCLAS
  Future<void> guardar(Producto producto) async {
    try {
      await _repository.guardar(producto);
      await cargarDatos(); // ✅ LÍNEA CLAVE: recarga la lista automáticamente después de guardar
    } catch (e) {
      rethrow;
    }
  }

  Future<void> borrar(int id) async {
    try {
      await _repository.eliminarLogico(id);
      await cargarDatos();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> asignarRegimenAFactura(Producto producto, Map<String, dynamic> regimen) async {
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
      await _repository.actualizarNivelStock(
        id,
        (cantidad as num).toDouble(),
      );
      await cargarDatos();
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