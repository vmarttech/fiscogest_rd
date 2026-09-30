import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/core/database/database_provider.dart';
import 'package:fiscogest_rd/features/comercial/data/repositories/compra_repository_impl.dart';
import 'package:fiscogest_rd/features/comercial/data/repositories/inventario_repository_impl.dart';
import 'package:fiscogest_rd/features/comercial/data/repositories/producto_repository_impl.dart';
import 'package:fiscogest_rd/features/comercial/data/repositories/proveedor_repository_impl.dart';
import 'package:fiscogest_rd/features/comercial/data/repositories/promocion_repository_impl.dart';
import 'package:fiscogest_rd/features/comercial/domain/repositories/i_compra_repository.dart';
import 'package:fiscogest_rd/features/comercial/domain/repositories/i_inventario_repository.dart';
import 'package:fiscogest_rd/features/comercial/domain/repositories/i_producto_repository.dart';
import 'package:fiscogest_rd/features/comercial/domain/repositories/i_promocion_repository.dart';
import 'package:fiscogest_rd/features/proveedores/domain/repositories/i_proveedor_repository.dart';
import 'package:fiscogest_rd/features/caja/domain/repositories/i_caja_repository.dart';
import 'package:fiscogest_rd/features/caja/data/repositories/caja_repository_impl.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/caja_movimientos_dao.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/caja_sesiones_dao.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/cuentas_pagar_dao.dart';
import 'package:fiscogest_rd/features/estadisticas/domain/repositories/i_estadisticas_repository.dart';
import 'package:fiscogest_rd/features/estadisticas/data/repositories/estadisticas_repository_impl.dart';
import 'package:fiscogest_rd/features/reportes/domain/repositories/i_reportes_repository.dart';
import 'package:fiscogest_rd/features/reportes/data/repositories/reportes_repository_impl.dart';
import 'package:fiscogest_rd/features/clientes/domain/interfaces/i_cliente_repository.dart';
import 'package:fiscogest_rd/features/clientes/data/repositories/cliente_repository_impl.dart';
import 'package:fiscogest_rd/features/clientes/data/dao/cliente_dao.dart';
import 'package:fiscogest_rd/features/comercial/data/datasources/promocion_datasource.dart';
import 'package:fiscogest_rd/features/inventario/data/datasources/drift_kardex_datasource.dart';
import 'package:fiscogest_rd/features/inventario/data/repositories/kardex_repository_impl.dart';
import 'package:fiscogest_rd/features/inventario/data/repositories/producto_repository_impl.dart' as inventario_producto;
import 'package:fiscogest_rd/features/inventario/domain/interfaces/ikardex_repository.dart';
import 'package:fiscogest_rd/features/inventario/domain/interfaces/i_producto_repository.dart' as inventario_repo;
import 'package:riverpod/riverpod.dart';

final promocionDatasourceProvider = Provider<PromocionDatasource>((ref) {
  return PromocionDatasource();
});

final promocionRepositoryProvider = Provider<IPromocionRepository>((ref) {
  final datasource = ref.watch(promocionDatasourceProvider);
  return PromocionRepositoryImpl(datasource);
});

final compraRepositoryProvider = Provider<ICompraRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return CompraRepositoryImpl(db);
});

final inventarioRepositoryProvider = Provider<IInventarioRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return InventarioRepositoryImpl(db);
});

final driftKardexDatasourceProvider = Provider<DriftKardexDatasource>((ref) {
  return DriftKardexDatasource(ref.watch(databaseProvider));
});

final kardexRepositoryProvider = Provider<IKardexRepository>((ref) {
  return KardexRepositoryImpl(ref.watch(driftKardexDatasourceProvider));
});

final productoRepositoryProvider = Provider<IProductoRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return ProductoRepositoryImpl(db);
});

final inventarioProductoRepositoryProvider =
    Provider<inventario_repo.IProductoRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final kardexRepo = ref.watch(kardexRepositoryProvider);
  return inventario_producto.ProductoRepositoryImpl(db, kardexRepo);
});

final proveedorRepositoryProvider = Provider<IProveedorRepository>((ref) {
  return ProveedorRepositoryImpl();
});

final cuentasPagarDaoProvider = Provider<CuentasPagarDao>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return CuentasPagarDao(db);
});

final cajaSesionesDaoProvider = Provider<CajaSesionesDao>((ref) {
  final db = ref.watch(databaseProvider);
  return CajaSesionesDao(db);
});

final cajaMovimientosDaoProvider = Provider<CajaMovimientosDao>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return CajaMovimientosDao(db);
});

final cajaRepositoryProvider = Provider<ICajaRepository>((ref) {
  final dao = ref.watch(cajaMovimientosDaoProvider);
  final sesiones = ref.watch(cajaSesionesDaoProvider);
  return CajaRepositoryImpl(
    cajaMovimientosDao: dao,
    cajaSesionesDao: sesiones,
  );
});

final clienteDaoProvider = Provider<ClienteDao>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return ClienteDao(db);
});

final clienteRepositoryProvider = Provider<IClienteRepository>((ref) {
  final dao = ref.watch(clienteDaoProvider);
  return ClienteRepositoryImpl(dao);
});

final estadisticasRepositoryProvider = Provider<IEstadisticasRepository>((ref) {
  return EstadisticasRepositoryImpl();
});

final reportesRepositoryProvider = Provider<IReportesRepository>((ref) {
  return ReportesRepositoryImpl();
});
