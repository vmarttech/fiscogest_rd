import 'package:fiscogest_rd/core/database/database_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/core/database/app_database.dart'; // ✅ Única BD oficial
import 'package:fiscogest_rd/features/ajustes_inventario/domain/entities/ajuste_inventario.dart';
import 'package:fiscogest_rd/features/ajustes_inventario/data/repositories/ajuste_inventario_repository_impl.dart';
import 'package:fiscogest_rd/core/interfaces/inventario_repository_interface.dart';
 // ✅ Interfaz desacoplada
import 'package:fiscogest_rd/features/inventario/data/repositories/inventario_repository_impl.dart';
import 'package:fiscogest_rd/features/inventario/presentation/providers/producto_providers.dart';

// ❌ ELIMINADOS: Providers de BD por módulo (violan SSOT)
// final ajusteInventarioDbProvider = ...
// final inventarioDbProvider = ...

final ajusteInventarioRepositoryProvider = Provider<AjusteInventarioRepositoryImpl>((ref) {
  // ✅ Se obtiene la única instancia de BD desde el Core
  final AppDatabase appDb = ref.read(databaseProvider);
  
  // ✅ Se inyecta la implementación asignada a la interfaz
  final InventarioRepositoryInterface inventarioRepo = InventarioRepositoryImpl(appDb);
  
  // ✅ Se pasa solo dependencias desacopladas
  return AjusteInventarioRepositoryImpl(inventarioRepo, appDb);
});

final registrarAjusteProvider = Provider<Future<void> Function(AjusteInventario)>((ref) {
  final repo = ref.read(ajusteInventarioRepositoryProvider);
  return (ajuste) async {
    await repo.registrarAjuste(ajuste);
    ref.invalidate(productoControllerProvider);
    ref.invalidate(ajusteInventarioListProvider);
  };
});

final ajusteInventarioListProvider = FutureProvider<List<AjusteInventario>>((ref) async {
  final repo = ref.read(ajusteInventarioRepositoryProvider);
  return repo.listarAjustes();
});