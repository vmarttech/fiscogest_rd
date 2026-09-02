import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:fiscogest_rd/core/navigation/app_router.dart';
import 'package:fiscogest_rd/core/providers/core_providers.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/core/database/database_provider.dart';
import 'package:fiscogest_rd/core/dependency_injection/repository_injection.dart';
import 'package:fiscogest_rd/core/interfaces/inventario_repository_interface.dart';
import 'package:fiscogest_rd/core/interfaces/inventario_fisico_repository_interface.dart';

import 'package:fiscogest_rd/features/inventario/domain/entities/producto.dart';
import 'package:fiscogest_rd/features/inventario_fisico/data/repositories/inventario_fisico_repository_impl.dart';
import 'package:fiscogest_rd/features/ajustes_inventario/data/repositories/ajuste_inventario_repository_impl.dart';
import 'package:fiscogest_rd/features/ajustes_inventario/domain/repositories/ajuste_inventario_repository.dart';
import 'package:fiscogest_rd/features/ajustes_inventario/presentation/providers/ajuste_inventario_provider.dart'
    as ajuste_prov;

class _InventarioRepositoryAdapter implements InventarioRepositoryInterface {
  _InventarioRepositoryAdapter(this._db);

  final AppDatabase _db;

  @override
  Future<void> actualizarStock(int productoId, double nuevoStock) async {
    await (_db.update(_db.productosTable)
          ..where((fila) => fila.id.equals(productoId)))
        .write(ProductosTableCompanion(stock: Value(nuevoStock)));
  }

  @override
  Future<void> actualizarProducto(Producto producto) async {
    if (producto.id == null) return;
    await (_db.update(
      _db.productosTable,
    )..where((t) => t.id.equals(producto.id!))).write(
      ProductosTableCompanion(
        codigo: Value(producto.codigo),
        nombre: Value(producto.nombre),
        precioCompra: Value(producto.precioCompra),
        precioVenta: Value(producto.precioVenta),
        stock: Value(producto.stock),
        stockMinimo: Value(producto.stockMinimo),
        categoriaId: Value(producto.categoriaId),
        marcaId: Value(producto.marcaId),
        unidadMedidaId: Value(producto.unidadMedidaId),
        activo: Value(producto.activo ? 1 : 0),
      ),
    );
  }

  @override
  Future<void> crearProducto(Producto producto) async {
    await _db
        .into(_db.productosTable)
        .insert(
          ProductosTableCompanion(
            codigo: Value(producto.codigo),
            nombre: Value(producto.nombre),
            precioCompra: Value(producto.precioCompra),
            precioVenta: Value(producto.precioVenta),
            stock: Value(producto.stock),
            stockMinimo: Value(producto.stockMinimo),
            categoriaId: Value(producto.categoriaId),
            marcaId: Value(producto.marcaId),
            unidadMedidaId: Value(producto.unidadMedidaId),
            activo: Value(producto.activo ? 1 : 0),
          ),
        );
  }

  @override
  Future<void> eliminarProducto(int id) async {
    await (_db.delete(_db.productosTable)..where((t) => t.id.equals(id))).go();
  }

  @override
  Future<Producto?> obtenerProductoPorCodigo(String codigo) async {
    final row = await (_db.select(
      _db.productosTable,
    )..where((t) => t.codigo.equals(codigo))).getSingleOrNull();
    if (row == null) return null;
    return Producto(
      id: row.id,
      codigo: row.codigo,
      nombre: row.nombre,
      precioCompra: row.precioCompra ?? 0.0,
      precioVenta: row.precioVenta ?? 0.0,
      stock: row.stock,
      stockMinimo: row.stockMinimo,
      categoriaId: row.categoriaId,
      marcaId: row.marcaId,
      unidadMedidaId: row.unidadMedidaId,
      activo: row.activo == 1,
    );
  }

  @override
  Future<Producto?> obtenerProductoPorId(int id) async {
    final row = await (_db.select(
      _db.productosTable,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    if (row == null) return null;
    return Producto(
      id: row.id,
      codigo: row.codigo,
      nombre: row.nombre,
      precioCompra: row.precioCompra ?? 0.0,
      precioVenta: row.precioVenta ?? 0.0,
      stock: row.stock,
      stockMinimo: row.stockMinimo,
      categoriaId: row.categoriaId,
      marcaId: row.marcaId,
      unidadMedidaId: row.unidadMedidaId,
      activo: row.activo == 1,
    );
  }

  @override
  Future<List<Producto>> listarProductos() async {
    final results = await _db.select(_db.productosTable).get();
    return results
        .map(
          (row) => Producto(
            id: row.id,
            codigo: row.codigo,
            nombre: row.nombre,
            precioCompra: row.precioCompra ?? 0.0,
            precioVenta: row.precioVenta ?? 0.0,
            stock: row.stock,
            stockMinimo: row.stockMinimo,
            categoriaId: row.categoriaId,
            marcaId: row.marcaId,
            unidadMedidaId: row.unidadMedidaId,
            activo: row.activo == 1,
          ),
        )
        .toList();
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es_DO', null);

  final db = AppDatabase();

  // ✅ Inicialización ÚNICA de toda la gráfica de dependencias
  await RepositoryInjection.initialize(db);

  final InventarioRepositoryInterface inventarioRepo =
      _InventarioRepositoryAdapter(db);
  final InventarioFisicoRepositoryInterface inventarioFisicoRepo =
      InventarioFisicoRepositoryImpl(db);
  final AjusteInventarioRepository ajusteInventarioRepo =
      AjusteInventarioRepositoryImpl(db);

  // ✅ INSTANCIA ÚNICA: Tomada de RepositoryInjection, NO creamos una nueva
  // De esta forma, VentaInventarioService y Riverpod comparten la MISMA instancia
  final ventasRepo = RepositoryInjection.instance.ventasRepository;

  final container = ProviderContainer(
    overrides: [
      databaseProvider.overrideWithValue(db),
      inventarioRepositoryProvider.overrideWithValue(inventarioRepo),
      inventarioFisicoRepositoryProvider.overrideWithValue(
        inventarioFisicoRepo,
      ),
      ajuste_prov.ajusteInventarioRepositoryProvider.overrideWithValue(
        ajusteInventarioRepo,
      ),
      ventasRepositoryProvider.overrideWithValue(ventasRepo),
    ],
  );

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const FiscoGestApp(),
    ),
  );
}

class FiscoGestApp extends ConsumerWidget {
  const FiscoGestApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'FiscoGest RD 3.0',
      debugShowCheckedModeBanner: false,
      routerConfig: ref.watch(appRouterProvider),
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blueGrey),
    );
  }
}
