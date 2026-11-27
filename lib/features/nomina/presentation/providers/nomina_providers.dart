import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/core/database/database_provider.dart';
import 'package:fiscogest_rd/features/nomina/data/repositories/empleado_repository.dart';
import 'package:fiscogest_rd/features/nomina/data/repositories/planilla_repository.dart';
import 'package:fiscogest_rd/features/nomina/data/repositories/liquidacion_repository.dart';
import 'package:fiscogest_rd/features/nomina/domain/entities/empleado.dart';
import 'package:fiscogest_rd/features/nomina/domain/entities/planilla.dart';
import 'package:fiscogest_rd/features/nomina/domain/entities/liquidacion_historial.dart';

final empleadoRepositoryProvider = Provider<EmpleadoRepository>((ref) {
  return EmpleadoRepository(ref.watch(databaseProvider));
});

final planillaRepositoryProvider = Provider<PlanillaRepository>((ref) {
  return PlanillaRepository(ref.watch(databaseProvider));
});

final liquidacionRepositoryProvider = Provider<LiquidacionRepository>((ref) {
  return LiquidacionRepository(ref.watch(databaseProvider));
});

final empleadosListaProvider =
    FutureProvider.autoDispose<List<Empleado>>((ref) async {
  return ref.watch(empleadoRepositoryProvider).listar();
});

final planillasListaProvider =
    FutureProvider.autoDispose<List<Planilla>>((ref) async {
  return ref.watch(planillaRepositoryProvider).listar();
});

final planillaDetalleProvider =
    FutureProvider.autoDispose.family<Planilla?, int>((ref, id) async {
  return ref.watch(planillaRepositoryProvider).obtener(id);
});

final liquidacionesHistorialProvider =
    FutureProvider.autoDispose<List<LiquidacionHistorial>>((ref) async {
  return ref.watch(liquidacionRepositoryProvider).listar();
});
