import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/core/database/database_provider.dart';
import 'package:fiscogest_rd/features/reportes/data/reportes_repository.dart';
import 'package:fiscogest_rd/features/reportes/domain/kpi_models.dart';

final reportesRepositoryProvider = Provider<ReportesRepository>((ref) {
  return ReportesRepository(ref.watch(databaseProvider));
});

final dashboardSnapshotProvider = FutureProvider.autoDispose<DashboardSnapshot>(
  (ref) async {
    return ref.watch(reportesRepositoryProvider).cargarDashboard();
  },
);

final periodoDashProvider = StateProvider.autoDispose<PeriodoDash>(
  (ref) => PeriodoDash.hoy,
);


/// Rango visible en la barra de filtros (inclusive).
final rangoDashProvider = StateProvider.autoDispose<(DateTime, DateTime)>((ref) {
  final n = DateTime.now();
  final hoy = DateTime(n.year, n.month, n.day);
  return (hoy, hoy);
});

/// Preferencia de base de comparación (UI).
enum CompararCon { periodoPrevio, mesAnterior, anioAnterior }

final compararDashProvider = StateProvider.autoDispose<CompararCon>(
  (ref) => CompararCon.periodoPrevio,
);
