import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/core/database/database_provider.dart';
import 'package:fiscogest_rd/features/almacenes/data/dao/almacenes_dao.dart';
import 'package:fiscogest_rd/features/almacenes/data/dao/stock_almacen_dao.dart';
import 'package:fiscogest_rd/features/almacenes/domain/entities/almacen.dart';
import 'package:fiscogest_rd/features/licencias/domain/licencia_gates.dart';
import 'package:fiscogest_rd/features/licencias/presentation/providers/licencia_providers.dart';

final almacenesHabilitadosProvider = Provider<bool>((ref) {
  return ref.watch(licenciaActualProvider).maybeWhen(
        data: (lic) => LicenciaGates(lic).permiteAlmacenes,
        orElse: () => false,
      );
});

final almacenesDaoProvider = Provider<AlmacenesDao>((ref) {
  return AlmacenesDao(ref.watch(databaseProvider));
});

final stockAlmacenDaoProvider = Provider<StockAlmacenDao>((ref) {
  return StockAlmacenDao(ref.watch(databaseProvider));
});

class AlmacenesNotifier extends StateNotifier<AsyncValue<List<Almacen>>> {
  AlmacenesNotifier(this._dao, this._stock) : super(const AsyncValue.loading()) {
    cargar();
  }

  final AlmacenesDao _dao;
  final StockAlmacenDao _stock;

  Future<void> cargar() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _dao.asegurarPrincipal();
      try {
        await _stock.sembrarDesdeProductos();
      } catch (_) {
        // Unique / carrera: el stock ya está sembrado.
      }
      return _dao.obtenerTodos();
    });
  }

  Future<void> guardar(Almacen a) async {
    if (a.id == null) {
      await _dao.insertar(a);
    } else {
      await _dao.actualizar(a);
    }
    await cargar();
  }

  Future<void> marcarPrincipal(int id) async {
    await _dao.marcarPrincipal(id);
    await cargar();
  }
}

final almacenesControllerProvider =
    StateNotifierProvider<AlmacenesNotifier, AsyncValue<List<Almacen>>>((ref) {
  return AlmacenesNotifier(
    ref.watch(almacenesDaoProvider),
    ref.watch(stockAlmacenDaoProvider),
  );
});
