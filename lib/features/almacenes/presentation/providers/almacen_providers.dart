import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/core/database/database_provider.dart';
import 'package:fiscogest_rd/features/almacenes/data/dao/almacenes_dao.dart';
import 'package:fiscogest_rd/features/almacenes/domain/entities/almacen.dart';

/// Controlador CRUD de almacenes. La lista se expone como AsyncValue para
/// compatibilidad con los watchers existentes; las mutaciones van por
/// `.notifier.guardar(...)` / `.notifier.marcarPrincipal(id)`.
class AlmacenesController extends AsyncNotifier<List<Almacen>> {
  AlmacenesDao get _dao => AlmacenesDao(ref.read(databaseProvider));

  @override
  Future<List<Almacen>> build() async {
    final db = ref.watch(databaseProvider);
    return AlmacenesDao(db).obtenerTodos();
  }

  Future<void> guardar(Almacen almacen) async {
    if (almacen.id == null) {
      await _dao.insertar(almacen);
    } else {
      await _dao.actualizar(almacen);
    }
    state = AsyncData(await _dao.obtenerTodos());
  }

  Future<void> marcarPrincipal(int id) async {
    await _dao.marcarPrincipal(id);
    state = AsyncData(await _dao.obtenerTodos());
  }
}

final almacenesControllerProvider =
    AsyncNotifierProvider<AlmacenesController, List<Almacen>>(
  AlmacenesController.new,
);

/// Alias en singular que usan la página de compras y los selectores.
final almacenControllerProvider = almacenesControllerProvider;

/// Interruptor de la función multi-almacén; habilitada para esta fase.
final almacenesHabilitadosProvider = Provider<bool>((ref) => true);
