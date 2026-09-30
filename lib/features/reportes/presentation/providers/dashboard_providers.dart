import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/core/database/database_provider.dart';
import 'package:fiscogest_rd/features/reportes/data/reportes_repository.dart';
import 'package:fiscogest_rd/features/reportes/domain/kpi_models.dart';

final reportesRepositoryProvider = Provider<ReportesRepository>((ref) {
  return ReportesRepository(ref.watch(databaseProvider));
});

final dashboardSnapshotProvider =
    FutureProvider.autoDispose<DashboardSnapshot>((ref) async {
  return ref.watch(reportesRepositoryProvider).cargarDashboard();
});

final periodoDashProvider =
    StateProvider.autoDispose<PeriodoDash>((ref) => PeriodoDash.hoy);
