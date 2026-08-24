import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/features/comercial/data/repositories/compra_repository_impl.dart';
import 'package:fiscogest_rd/features/comercial/data/repositories/inventario_repository_impl.dart';
import 'package:fiscogest_rd/features/comercial/data/repositories/producto_repository_impl.dart';
import 'package:fiscogest_rd/features/comercial/data/repositories/proveedor_repository_impl.dart';
import 'package:fiscogest_rd/features/comercial/data/repositories/promocion_repository_impl.dart';
import 'package:fiscogest_rd/features/comercial/domain/repositories/i_compra_repository.dart';
import 'package:fiscogest_rd/features/comercial/domain/repositories/i_inventario_repository.dart';
import 'package:fiscogest_rd/features/comercial/domain/repositories/i_producto_repository.dart';
import 'package:fiscogest_rd/features/comercial/domain/repositories/i_proveedor_repository.dart';
import 'package:fiscogest_rd/features/comercial/domain/repositories/i_promocion_repository.dart';
import 'package:fiscogest_rd/features/comercial/data/datasources/promocion_datasource.dart';
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
  return InventarioRepositoryImpl();
});

final productoRepositoryProvider = Provider<IProductoRepository>((ref) {
  return ProductoRepositoryImpl();
});

final proveedorRepositoryProvider = Provider<IProveedorRepository>((ref) {
  return ProveedorRepositoryImpl();
});
