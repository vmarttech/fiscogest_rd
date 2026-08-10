import 'package:fiscogest_rd/core/database/database_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/features/inventario_fisico/domain/entities/conteo_fisico.dart';
import 'package:fiscogest_rd/features/inventario_fisico/domain/usecases/registrar_conteo_usecase.dart';
import 'package:fiscogest_rd/features/inventario_fisico/domain/usecases/listar_diferencias_usecase.dart';
import 'package:fiscogest_rd/features/inventario_fisico/domain/usecases/aprobar_ajustes_usecase.dart';
import 'package:fiscogest_rd/features/inventario_fisico/domain/usecases/generar_reporte_usecase.dart';
import 'package:fiscogest_rd/features/inventario_fisico/data/repositories/inventario_fisico_repository_impl.dart';
import 'package:fiscogest_rd/core/interfaces/inventario_fisico_repository_interface.dart';

// ✅ Fuente de datos centralizada oficial (SSOT)
final inventarioFisicoDbProvider = Provider<AppDatabase>((ref) {
  return ref.watch(databaseProvider);
});

// ✅ Repositorio: usa la INTERFAZ como tipo y AppDatabase
final inventarioFisicoRepoProvider = Provider<InventarioFisicoRepositoryInterface>((ref) {
  return InventarioFisicoRepositoryImpl(ref.watch(inventarioFisicoDbProvider));
});

// ✅ Casos de uso: todos reciben la interfaz, funcionan sin errores
final registrarConteoProvider = Provider<RegistrarConteoUsecase>((ref) {
  return RegistrarConteoUsecase(ref.watch(inventarioFisicoRepoProvider));
});

final listarDiferenciasProvider = Provider<ListarDiferenciasUsecase>((ref) {
  return ListarDiferenciasUsecase(ref.watch(inventarioFisicoRepoProvider));
});

final aprobarAjustesProvider = Provider<AprobarAjustesUsecase>((ref) {
  return AprobarAjustesUsecase(ref.watch(inventarioFisicoRepoProvider));
});

final generarReporteProvider = Provider<GenerarReporteUsecase>((ref) {
  return GenerarReporteUsecase(ref.watch(inventarioFisicoRepoProvider));
});

// ✅ Listado con tipo exacto y llamado directo
final listaConteosProvider = FutureProvider<List<ConteoFisico>>((ref) async {
  return ref.watch(inventarioFisicoRepoProvider).listarConteos();
});
