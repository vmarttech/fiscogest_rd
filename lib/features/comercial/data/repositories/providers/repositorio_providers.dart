import 'package:fiscogest_rd/features/comercial/data/datasources/promocion_datasource.dart';
import 'package:fiscogest_rd/features/comercial/data/repositories/promocion_repository_impl.dart';
import 'package:fiscogest_rd/features/comercial/domain/repositories/i_promocion_repository.dart';
import 'package:riverpod/riverpod.dart';

final promocionDatasourceProvider = Provider<PromocionDatasource>((ref) {
  return PromocionDatasource();
});

final promocionRepositoryProvider = Provider<IPromocionRepository>((ref) {
  final datasource = ref.watch(promocionDatasourceProvider);
  return PromocionRepositoryImpl(datasource);
});
