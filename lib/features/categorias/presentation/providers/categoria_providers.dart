import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/categoria.dart';

class CategoriaNotifier extends StateNotifier<AsyncValue<List<Categoria>>> {
  CategoriaNotifier() : super(AsyncValue.data([
    Categoria(id: 1, nombre: 'General', descripcion: 'Categoría general por defecto'),
    Categoria(id: 2, nombre: 'Bebidas', descripcion: 'Bebidas y refrescos'),
    Categoria(id: 3, nombre: 'Alimentos', descripcion: 'Productos alimenticios y abarrotes'),
  ]));

  Future<void> guardar(Categoria categoria) async {
    state.whenData((lista) {
      final existe = lista.any((c) => c.nombre.trim().toLowerCase() == categoria.nombre.trim().toLowerCase());
      if (existe) {
        throw Exception('Ya existe una categoría registrada con ese nombre.');
      }
      final nuevoId = lista.isEmpty ? 1 : (lista.map((e) => e.id ?? 0).reduce((a, b) => a > b ? a : b) + 1);
      final nuevaCategoria = categoria.copyWith(id: nuevoId);
      state = AsyncValue.data([...lista, nuevaCategoria]);
    });
  }

  Future<void> actualizar(Categoria categoria) async {
    state.whenData((lista) {
      final duplicada = lista.any((c) => c.id != categoria.id && c.nombre.trim().toLowerCase() == categoria.nombre.trim().toLowerCase());
      if (duplicada) {
        throw Exception('Ya existe otra categoría con ese nombre.');
      }
      state = AsyncValue.data([
        for (var c in lista)
          if (c.id == categoria.id) categoria else c
      ]);
    });
  }

  Future<void> eliminar(int id) async {
    state.whenData((lista) {
      state = AsyncValue.data(lista.where((c) => c.id != id).toList());
    });
  }
}

final categoriaControllerProvider = StateNotifierProvider<CategoriaNotifier, AsyncValue<List<Categoria>>>((ref) {
  return CategoriaNotifier();
});
