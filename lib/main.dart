import 'package:fiscogest_rd/features/almacenes/data/dao/stock_almacen_dao.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fiscogest_rd/core/sync/supabase/roles_acceso_sync.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:drift/drift.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:fiscogest_rd/core/navigation/app_router.dart';
import 'package:fiscogest_rd/core/auth/sesion_provider.dart';
import 'package:fiscogest_rd/core/auth/sesion_persistente.dart';
import 'package:fiscogest_rd/core/sync/supabase/sesion_nube.dart';
import 'package:fiscogest_rd/core/providers/core_providers.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/core/database/database_provider.dart';
import 'package:fiscogest_rd/features/licencias/domain/licencia_service.dart';
import 'package:fiscogest_rd/features/licencias/domain/dispositivo_service.dart';
import 'package:fiscogest_rd/core/sync/supabase/supabase_config.dart';
import 'package:fiscogest_rd/core/sync/supabase/renovar_token.dart';
import 'package:fiscogest_rd/core/sync/supabase/sync_scheduler.dart';
import 'package:fiscogest_rd/core/dependency_injection/repository_injection.dart';
import 'package:fiscogest_rd/core/interfaces/inventario_repository_interface.dart';
import 'package:fiscogest_rd/core/interfaces/inventario_fisico_repository_interface.dart';
import 'package:fiscogest_rd/features/inventario/domain/entities/producto.dart';
import 'package:fiscogest_rd/features/inventario_fisico/data/repositories/inventario_fisico_repository_impl.dart';
import 'package:fiscogest_rd/features/ajustes_inventario/data/repositories/ajuste_inventario_repository_impl.dart';
import 'package:fiscogest_rd/features/ajustes_inventario/domain/repositories/ajuste_inventario_repository.dart';
import 'package:fiscogest_rd/features/ajustes_inventario/presentation/providers/ajuste_inventario_provider.dart'
    as ajuste_prov;
import 'package:fiscogest_rd/core/ui/fisco_gest_notifications.dart';
import 'package:fiscogest_rd/core/ui/app_theme.dart';
import 'package:fiscogest_rd/core/ui/app_breakpoints.dart';
import 'package:fiscogest_rd/core/services/update_checker.dart';
import 'package:fiscogest_rd/core/services/usb_barcode_scanner_service.dart';
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';
import 'dart:io';

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
  // Catálogo de roles: caché local inmediata; pull nube tras login.
  await RolesAccesoSync.cargarDesdePrefsOFallback();

  if (Platform.isAndroid) {
    await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();
  }

  await initializeDateFormatting('es_DO', null);
  final db = AppDatabase();
  await _seedStockAlmacenUnaVez(db);
  await RepositoryInjection.initialize(db);

  // Recupera una licencia concedida y prepara la identidad del dispositivo.
  try {
    final licenciaSvc = LicenciaService(db);
    await licenciaSvc.ensureLicenciaInicial();
    await DispositivoService(db).ensureDispositivoRegistrado();
    debugPrint(
      'Supabase configurado: ${SupabaseConfig.isConfigured} '
      'urlLen=${SupabaseConfig.url.length} keyLen=${SupabaseConfig.anonKey.length}',
    );
    if (SupabaseConfig.isConfigured) {
      // Despertar Supabase en segundo plano (no bloquea el arranque)
      unawaited(() async {
        try {
          final ok = await SupabaseConfig.hayRed();
          debugPrint(
            'Wake Supabase: ${ok ? "OK / despierto" : "sin respuesta"}',
          );
        } catch (e) {
          debugPrint('Wake Supabase: $e');
        }
      }());

      try {
        unawaited(() async {
          await RenovarToken.asegurar();
          debugPrint('main: push al entrar o cada 5 min');
        }());
      } catch (e, st) {
        debugPrint('Sync nube: $e');
        debugPrint('$st');
      }
      // Reintentos periódicos (fase 1)
      SyncScheduler(db).start();
    } else {
      debugPrint(
        'DispositivoSync: OMITIDO — falta --dart-define SUPABASE_URL y SUPABASE_ANON_KEY',
      );
    }
    await licenciaSvc.expirarPedidosVencidos();
    // UNA vez en tu PC (MartTech vitalicio), descomenta, corre y vuelve a comentar:
    // await licenciaSvc.activarDesarrolladorVitalicio();
  } catch (e, st) {
    debugPrint('Licencia ensure: $e');
    debugPrint('$st');
  }
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
  final prefs = await SharedPreferences.getInstance();
  container.read(appThemeProvider.notifier).state = AppThemeOption.fromName(
    prefs.getString('app_theme'),
  );
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const FiscoGestApp(),
    ),
  );
}

class FiscoGestApp extends ConsumerStatefulWidget {
  const FiscoGestApp({super.key});

  @override
  ConsumerState<FiscoGestApp> createState() => _FiscoGestAppState();
}

class _FiscoGestAppState extends ConsumerState<FiscoGestApp> {
  @override
  void initState() {
    super.initState();
    // Scanner USB (keyboard wedge): activo en toda la app comercial.
    // En móvil no molesta; en PC reconoce cualquier lector HID al conectar.
    UsbBarcodeScannerService.instance.start();
  }

  @override
  Widget build(BuildContext context) {
    final appTheme = ref.watch(appThemeProvider);
    final baseTheme = ThemeData(
      useMaterial3: true,
      colorSchemeSeed: appTheme.seedColor,
    );
    final appColorScheme = baseTheme.colorScheme.copyWith(
      primary: appTheme == AppThemeOption.teal
          ? baseTheme.colorScheme.primary
          : appTheme.seedColor,
      onPrimary: Colors.white,
      primaryContainer: Color.lerp(
        const Color(0xFFF8FAFC),
        appTheme.seedColor,
        0.08,
      ),
      onPrimaryContainer: const Color(0xFF1E293B),
    );
    return MaterialApp.router(
      title: 'VendiFlux',
      debugShowCheckedModeBanner: false,
      routerConfig: ref.watch(appRouterProvider),
      theme: baseTheme.copyWith(colorScheme: appColorScheme),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('es', 'DO'), Locale('en', 'US')],
      locale: const Locale('es', 'DO'),
      builder: (context, child) {
        // context AQUÍ sí tiene Navigator → diálogos de update OK
        final media = MediaQuery.of(context);
        final desktop = AppBreakpoints.useWideChrome(context);
        final systemScale = media.textScaler.scale(1.0);
        final desktopScale = (systemScale * 1.12).clamp(1.0, 1.4);
        return _UpdateGate(
          child: MediaQuery(
            data: desktop
                ? media.copyWith(textScaler: TextScaler.linear(desktopScale))
                : media,
            child: Stack(
              children: [
                if (child != null) child,
                const FiscoGestNotificationOverlay(),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Revisa update.json una sola vez, con un context bajo MaterialApp.
class _UpdateGate extends ConsumerStatefulWidget {
  const _UpdateGate({required this.child});
  final Widget child;

  @override
  ConsumerState<_UpdateGate> createState() => _UpdateGateState();
}

class _UpdateGateState extends ConsumerState<_UpdateGate>
    with WidgetsBindingObserver {
  bool _busy = false;
  bool _checkingInactivity = false;
  DateTime? _lastCheck;
  Timer? _inactivityTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _inactivityTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => unawaited(_enforceInactivityTimeout()),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future<void>.delayed(const Duration(seconds: 2), _runCheck);
    });
  }

  @override
  void dispose() {
    _inactivityTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_enforceInactivityTimeout());
      _runCheck();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      unawaited(SesionPersistente.guardarActividadActual());
    }
  }

  void _recordUserActivity() {
    final sesion = ref.read(sesionProvider);
    if (sesion != null && sesion.id > 0) {
      unawaited(SesionPersistente.registrarActividad());
    }
  }

  Future<void> _enforceInactivityTimeout() async {
    final sesion = ref.read(sesionProvider);
    if (_checkingInactivity || sesion == null || sesion.id <= 0) return;
    _checkingInactivity = true;
    try {
      if (!await SesionPersistente.expirada()) return;
      await SesionPersistente.limpiar();
      await SesionNube.clear();
      if (!mounted) return;
      ref.read(sesionProvider.notifier).state = null;
      ref.read(appRouterProvider).go('/login');
    } finally {
      _checkingInactivity = false;
    }
  }

  Future<void> _runCheck() async {
    if (!mounted || _busy) return;
    final now = DateTime.now();
    if (_lastCheck != null &&
        now.difference(_lastCheck!) < const Duration(seconds: 30)) {
      return;
    }
    _busy = true;
    _lastCheck = now;
    try {
      final navigatorContext = appNavigatorKey.currentState?.overlay?.context;
      if (navigatorContext == null) {
        debugPrint(
          '[UpdateChecker] Navigator no disponible; '
          'se intentará comprobar de nuevo más adelante.',
        );
        _lastCheck = null;
        return;
      }
      await UpdateChecker.checkAndPrompt(navigatorContext);
    } catch (e, st) {
      debugPrint('[UpdateChecker] Error al comprobar o mostrar aviso: $e');
      debugPrint('$st');
    } finally {
      _busy = false;
    }
  }

  @override
  Widget build(BuildContext context) => Listener(
    onPointerDown: (_) => _recordUserActivity(),
    onPointerSignal: (_) => _recordUserActivity(),
    child: Focus(
      onKeyEvent: (_, __) {
        _recordUserActivity();
        return KeyEventResult.ignored;
      },
      child: widget.child,
    ),
  );
}

/// Siembra one-time (flag en SharedPreferences): productos.stock ->
/// stock_almacen del principal en filas inexistentes. No usar tool `dart run`
/// porque la app Flutter no corre en VM (dart:ui ausente).
Future<void> _seedStockAlmacenUnaVez(AppDatabase db) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    const flag = 'seed_stock_almacen_v1';
    if (prefs.getBool(flag) == true) return;
    await StockAlmacenDao(db).sembrarDesdeProductos();
    await prefs.setBool(flag, true);
  } catch (_) {
    // Reintento en el próximo arranque de la app.
  }
}
