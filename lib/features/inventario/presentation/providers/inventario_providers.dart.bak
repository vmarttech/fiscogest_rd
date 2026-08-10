import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/core/database/database_provider.dart';
import 'package:fiscogest_rd/features/inventario/data/datasources/drift_kardex_datasource.dart';
import 'package:fiscogest_rd/features/inventario/data/repositories/kardex_repository_impl.dart';
import 'package:fiscogest_rd/features/inventario/domain/interfaces/ikardex_repository.dart';

final driftKardexDatasourceProvider = Provider<DriftKardexDatasource>((ref) {
  return DriftKardexDatasource(ref.watch(databaseProvider));
});

final kardexRepositoryProvider = Provider<IKardexRepository>((ref) {
  return KardexRepositoryImpl(ref.watch(driftKardexDatasourceProvider));
});
