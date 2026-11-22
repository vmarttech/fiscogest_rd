import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fiscogest_rd/features/almacenes/domain/entities/almacen.dart';
import 'package:fiscogest_rd/features/almacenes/presentation/providers/almacen_providers.dart';

const _kAlmacenActivoId = 'almacen_activo_id';

/// Id del almacén/sucursal activo en este dispositivo.
final almacenActivoIdProvider =
    StateNotifierProvider<AlmacenActivoIdNotifier, int?>((ref) {
      return AlmacenActivoIdNotifier()..cargar();
    });

class AlmacenActivoIdNotifier extends StateNotifier<int?> {
  AlmacenActivoIdNotifier() : super(null);

  Future<void> cargar() async {
    final p = await SharedPreferences.getInstance();
    final id = p.getInt(_kAlmacenActivoId);
    state = id;
  }

  Future<void> setActivo(int? id) async {
    final p = await SharedPreferences.getInstance();
    if (id == null) {
      await p.remove(_kAlmacenActivoId);
    } else {
      await p.setInt(_kAlmacenActivoId, id);
    }
    state = id;
  }
}

/// Almacén activo resuelto (objeto). Si no hay id guardado, usa el principal.
final almacenActivoProvider = Provider<Almacen?>((ref) {
  final id = ref.watch(almacenActivoIdProvider);
  final listaAsync = ref.watch(almacenesControllerProvider);
  return listaAsync.maybeWhen(
    data: (lista) {
      if (lista.isEmpty) return null;
      if (id != null) {
        for (final a in lista) {
          if (a.id == id && a.activo) return a;
        }
      }
      for (final a in lista) {
        if (a.esPrincipal && a.activo) return a;
      }
      for (final a in lista) {
        if (a.activo) return a;
      }
      return lista.first;
    },
    orElse: () => null,
  );
});

/// Id efectivo a persistir en ventas/caja (nunca fuerza si lista vacía).
final almacenActivoIdEfectivoProvider = Provider<int?>((ref) {
  return ref.watch(almacenActivoProvider)?.id;
});
