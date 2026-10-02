import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/core/database/database_provider.dart';
import 'package:fiscogest_rd/features/gastos/data/repositories/gastos_repository.dart';
import 'package:fiscogest_rd/features/gastos/domain/entities/gasto.dart';

final gastosRepositoryProvider = Provider<GastosRepository>((ref) {
  return GastosRepository(ref.watch(databaseProvider));
});

final gastosListaProvider =
    FutureProvider.autoDispose<List<Gasto>>((ref) async {
  return ref.watch(gastosRepositoryProvider).listar();
});
