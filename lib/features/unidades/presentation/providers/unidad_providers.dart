import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/features/unidades/domain/entities/unidad.dart';

class UnidadNotifier extends StateNotifier<AsyncValue<List<Unidad>>> {
  UnidadNotifier() : super(AsyncValue.data([
    Unidad(id: 1, nombre: 'Unidad', abreviatura: 'UND'),
    Unidad(id: 2, nombre: 'Kilogramo', abreviatura: 'KG'),
    Unidad(id: 3, nombre: 'Litro', abreviatura: 'LT'),
    Unidad(id: 4, nombre: 'Metro', abreviatura: 'MT'),
  ]));

  Future<void> guardar(Unidad unidad) async {
    state.whenData((lista) {
      final existe = lista.any((u) => u.nombre.trim().toLowerCase() == unidad.nombre.trim().toLowerCase());
      if (existe) {
        throw Exception('Ya existe una unidad registrada con ese nombre.');
      }
      final nuevoId = lista.isEmpty ? 1 : (lista.map((e) => e.id ?? 0).reduce((a, b) => a > b ? a : b) + 1);
      final nuevaUnidad = unidad.copyWith(id: nuevoId);
      state = AsyncValue.data([...lista, nuevaUnidad]);
    });
  }

  Future<void> actualizar(Unidad unidad) async {
    state.whenData((lista) {
      final duplicada = lista.any((u) => u.id != unidad.id && u.nombre.trim().toLowerCase() == unidad.nombre.trim().toLowerCase());
      if (duplicada) {
        throw Exception('Ya existe otra unidad con ese nombre.');
      }
      state = AsyncValue.data([
        for (var u in lista)
          if (u.id == unidad.id) unidad else u
      ]);
    });
  }

  Future<void> eliminar(int id) async {
    state.whenData((lista) {
      state = AsyncValue.data(lista.where((u) => u.id != id).toList());
    });
  }
}

final unidadControllerProvider = StateNotifierProvider<UnidadNotifier, AsyncValue<List<Unidad>>>((ref) {
  return UnidadNotifier();
});
