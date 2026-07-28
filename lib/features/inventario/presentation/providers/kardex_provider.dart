import 'package:fiscogest_rd/core/database/database_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/features/inventario/domain/entities/kardex.dart';
import 'package:fiscogest_rd/features/inventario/domain/interfaces/ikardex_repository.dart';
import 'package:fiscogest_rd/features/inventario/domain/usecases/registrar_movimiento_kardex.dart';
import 'package:fiscogest_rd/features/inventario/data/repositories/kardex_repository_impl.dart';
import 'package:fiscogest_rd/features/inventario/data/datasources/drift_kardex_datasource.dart';


final driftKardexDatasourceProvider = Provider<DriftKardexDatasource>((ref) {
  return DriftKardexDatasource(ref.watch(databaseProvider));
});

final kardexRepositoryProvider = Provider<IKardexRepository>((ref) {
  return KardexRepositoryImpl(ref.watch(driftKardexDatasourceProvider));
});

final registrarMovimientoKardexProvider = Provider<RegistrarMovimientoKardex>((ref) {
  return RegistrarMovimientoKardex(ref.watch(kardexRepositoryProvider));
});

final kardexPorProductoProvider = FutureProvider.family<List<Kardex>, String>((ref, productoIdStr) async {
  final repo = ref.watch(kardexRepositoryProvider);
  if (productoIdStr.trim().isEmpty) return repo.obtenerTodoElHistorial();
  return repo.obtenerHistorialPorProducto(productoIdStr);
});
