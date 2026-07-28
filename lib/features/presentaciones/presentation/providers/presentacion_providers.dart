import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/features/presentaciones/domain/entities/presentacion.dart';

class PresentacionNotifier extends StateNotifier<AsyncValue<List<Presentacion>>> {
  PresentacionNotifier() : super(AsyncValue.data([
    Presentacion(id: 1, nombre: 'Unidad', abreviatura: 'UND'),
    Presentacion(id: 2, nombre: 'Caja', abreviatura: 'CAJ'),
    Presentacion(id: 3, nombre: 'Kilogramo', abreviatura: 'KG'),
    Presentacion(id: 4, nombre: 'Litro', abreviatura: 'LT'),
  ]));

  Future<void> guardar(Presentacion presentacion) async {
    state.whenData((lista) {
      final existe = lista.any((p) => p.nombre.trim().toLowerCase() == presentacion.nombre.trim().toLowerCase());
      if (existe) {
        throw Exception('Ya existe una presentación registrada con ese nombre.');
      }
      final nuevoId = lista.isEmpty ? 1 : (lista.map((e) => e.id ?? 0).reduce((a, b) => a > b ? a : b) + 1);
      final nuevaPresentacion = presentacion.copyWith(id: nuevoId);
      state = AsyncValue.data([...lista, nuevaPresentacion]);
    });
  }

  Future<void> actualizar(Presentacion presentacion) async {
    state.whenData((lista) {
      final duplicada = lista.any((p) => p.id != presentacion.id && p.nombre.trim().toLowerCase() == presentacion.nombre.trim().toLowerCase());
      if (duplicada) {
        throw Exception('Ya existe otra presentación con ese nombre.');
      }
      state = AsyncValue.data([
        for (var p in lista)
          if (p.id == presentacion.id) presentacion else p
      ]);
    });
  }

  Future<void> eliminar(int id) async {
    state.whenData((lista) {
      state = AsyncValue.data(lista.where((p) => p.id != id).toList());
    });
  }
}

final presentacionControllerProvider = StateNotifierProvider<PresentacionNotifier, AsyncValue<List<Presentacion>>>((ref) {
  return PresentacionNotifier();
});
