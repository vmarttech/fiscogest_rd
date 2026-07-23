import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/marca.dart';

class MarcaNotifier extends StateNotifier<AsyncValue<List<Marca>>> {
  MarcaNotifier() : super(AsyncValue.data([
    Marca(id: 1, nombre: 'Genérica', descripcion: 'Marca genérica por defecto'),
    Marca(id: 2, nombre: 'Nestlé', descripcion: 'Productos alimenticios'),
    Marca(id: 3, nombre: 'Coca-Cola', descripcion: 'Bebidas y refrescos'),
  ]));

  Future<void> guardar(Marca marca) async {
    state.whenData((lista) {
      final existe = lista.any((m) => m.nombre.trim().toLowerCase() == marca.nombre.trim().toLowerCase());
      if (existe) {
        throw Exception('Ya existe una marca registrada con ese nombre.');
      }
      final nuevoId = lista.isEmpty ? 1 : (lista.map((e) => e.id ?? 0).reduce((a, b) => a > b ? a : b) + 1);
      final nuevaMarca = marca.copyWith(id: nuevoId);
      state = AsyncValue.data([...lista, nuevaMarca]);
    });
  }

  Future<void> actualizar(Marca marca) async {
    state.whenData((lista) {
      final duplicada = lista.any((m) => m.id != marca.id && m.nombre.trim().toLowerCase() == marca.nombre.trim().toLowerCase());
      if (duplicada) {
        throw Exception('Ya existe otra marca con ese nombre.');
      }
      state = AsyncValue.data([
        for (var m in lista)
          if (m.id == marca.id) marca else m
      ]);
    });
  }

  Future<void> eliminar(int id) async {
    state.whenData((lista) {
      state = AsyncValue.data(lista.where((m) => m.id != id).toList());
    });
  }
}

final marcaControllerProvider = StateNotifierProvider<MarcaNotifier, AsyncValue<List<Marca>>>((ref) {
  return MarcaNotifier();
});
