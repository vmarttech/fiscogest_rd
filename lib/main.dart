import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
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

String _obtenerTituloVentana(String rutaActual) {
  return switch (rutaActual) {
    '/' => 'Dashboard - FiscoGest RD',
    '/sales' => 'Facturación y NC - FiscoGest RD',
    '/ventas' => 'Ventas - FiscoGest RD',
    '/ventas/cotizaciones/nueva' => 'Nueva Cotización - FiscoGest RD',
    '/ventas/cotizaciones/historial' => 'Historial de Cotizaciones - FiscoGest RD',
    '/ventas/apartados' => 'Apartados - FiscoGest RD',
    '/ventas/devoluciones' => 'Devoluciones - FiscoGest RD',
    '/ventas/descuentos' => 'Descuentos - FiscoGest RD',
    '/ventas/ofertas' => 'Ofertas - FiscoGest RD',
    '/ventas/cobrar' => 'Cuentas por Cobrar - FiscoGest RD',
    '/ventas/pagar' => 'Cuentas por Pagar - FiscoGest RD',
    '/compras' => 'Compras - FiscoGest RD',
    '/compras/lista' => 'Lista de Compras - FiscoGest RD',
    '/compras/registrar' => 'Registrar Compra - FiscoGest RD',
    '/compras/detalle' => 'Detalle de Compra - FiscoGest RD',
    '/compras/cuentas-pagar' => 'Cuentas por Pagar - FiscoGest RD',
    '/compras/recepcion' => 'Recepción de Compra - FiscoGest RD',
    '/inventario' => 'Inventario - FiscoGest RD',
    '/kardex' => 'Kárdex - FiscoGest RD',
    '/productos/nuevo' => 'Nuevo Producto - FiscoGest RD',
    '/inventario/entrada' => 'Entrada de Producto - FiscoGest RD',
    '/inventario/salida' => 'Salida de Producto - FiscoGest RD',
    '/inventario-fisico' => 'Inventario Físico - FiscoGest RD',
    '/inventario-fisico/listar' => 'Lista de Conteos - FiscoGest RD',
    '/diferencias-conteo-fisico' => 'Diferencias de Conteo - FiscoGest RD',
    '/lista-ajustes' => 'Lista de Ajustes - FiscoGest RD',
    '/registrar-ajuste' => 'Registrar Ajuste - FiscoGest RD',
    '/ajustes-inventario' => 'Ajustes de Inventario - FiscoGest RD',
    '/ajustes-inventario/nuevo' => 'Nuevo Ajuste - FiscoGest RD',
    '/clientes' => 'Clientes - FiscoGest RD',
    '/clientes/gestion' => 'Gestión de Cliente - FiscoGest RD',
    '/proveedores' => 'Proveedores - FiscoGest RD',
    '/transferencias/registrar' => 'Registrar Transferencia - FiscoGest RD',
    '/presentaciones' => 'Presentaciones - FiscoGest RD',
    '/categorias' => 'Categorías - FiscoGest RD',
    '/marcas' => 'Marcas - FiscoGest RD',
    '/unidades' => 'Unidades de Medida - FiscoGest RD',
    '/reports' => 'Reportes 606/607 - FiscoGest RD',
    '/impuestos' => 'Impuestos - FiscoGest RD',
    '/import-export' => 'Importar / Exportar - FiscoGest RD',
    '/configuracion' => 'Configuración - FiscoGest RD',
    _ when rutaActual.startsWith('/ventas/cotizaciones/') => 'Cotización - FiscoGest RD',
    _ when rutaActual.startsWith('/compras/') => 'Compras - FiscoGest RD',
    _ when rutaActual.startsWith('/inventario-fisico/') => 'Inventario Físico - FiscoGest RD',
    _ when rutaActual.startsWith('/clientes/') => 'Gestión de Cliente - FiscoGest RD',
    _ => 'FiscoGest RD',
  };
}

// Provider con protección: si no hay rutas, devuelve ruta vacía segura
final rutaActualProvider = Provider<String>((ref) {
  final router = ref.watch(appRouterProvider);
  try {
    final uri = router.state.uri;
    return uri.path;
  } catch (e) {
    return '/';
  }
});

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es_DO', null);
  final db = AppDatabase();
  await RepositoryInjection.initialize(db);
  final InventarioRepositoryInterface inventarioRepo =
      _InventarioRepositoryAdapter(db);
  final InventarioFisicoRepositoryInterface inventarioFisicoRepo =
      InventarioFisicoRepositoryImpl(db);
  final AjusteInventarioRepository ajusteInventarioRepo =
      AjusteInventarioRepositoryImpl(db);
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
    final rutaActual = ref.watch(rutaActualProvider);
    final tituloVentana = _obtenerTituloVentana(rutaActual);

    return MaterialApp.router(
      title: tituloVentana,
      debugShowCheckedModeBanner: false,
      routerConfig: ref.watch(appRouterProvider),
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blueGrey),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es', 'DO'),
        Locale('en', 'US'),
      ],
      locale: const Locale('es', 'DO'),
    );
  }
}
