import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/core/database/database_provider.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/ventas_dao.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/cuentas_cobrar_dao.dart';
import 'package:fiscogest_rd/features/ventas/domain/repositories/i_ventas_repository.dart';
import 'package:fiscogest_rd/features/ventas/data/repositories/ventas_repository_impl.dart';
import 'package:fiscogest_rd/features/ventas/domain/usecases/confirmar_venta_borrador.dart';
export 'package:fiscogest_rd/features/ventas/presentation/providers/venta_borrador_provider.dart';
export 'package:fiscogest_rd/features/ventas/presentation/providers/venta_borrador_servicio_provider.dart';
export 'registrar_venta_provider.dart';
export 'ventas_navegacion_provider.dart';
export 'venta_cargada_desde_historial_provider.dart';
export 'listas_ventas_providers.dart';
export 'descuentos_ofertas_providers.dart';
export 'registrar_venta_usecase_provider.dart';

final _ventasDaoProvider = Provider<VentasDao>((ref) {
  final AppDatabase db = ref.watch(databaseProvider);
  return VentasDao(db);
});

final _cuentasCobrarDaoProvider = Provider<CuentasCobrarDao>((ref) {
  final AppDatabase db = ref.watch(databaseProvider);
  return CuentasCobrarDao(db);
});

final ventasRepositoryProvider = Provider<IVentasRepository>((ref) {
  final ventasDao = ref.watch(_ventasDaoProvider);
  final cuentasCobrarDao = ref.watch(_cuentasCobrarDaoProvider);
  return VentasRepositoryImpl(ventasDao, cuentasCobrarDao);
});

final confirmarVentaBorradorUseCaseProvider = Provider<ConfirmarVentaBorrador>((
  ref,
) {
  final repositorio = ref.watch(ventasRepositoryProvider);
  return ConfirmarVentaBorrador(repositorio);
});
