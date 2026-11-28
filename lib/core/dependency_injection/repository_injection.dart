import 'package:fiscogest_rd/features/licencias/domain/licencia_service.dart';
import 'package:fiscogest_rd/features/licencias/domain/licencia_gates.dart';
import 'package:fiscogest_rd/core/contabilidad/data/repositories/asiento_repository_impl.dart';
import 'package:fiscogest_rd/core/contabilidad/data/repositories/plan_cuentas_repository_impl.dart';
import 'package:fiscogest_rd/core/contabilidad/domain/repositories/i_asiento_repository.dart';
import 'package:fiscogest_rd/core/contabilidad/domain/repositories/i_plan_cuentas_repository.dart';
import 'package:fiscogest_rd/core/contabilidad/domain/services/motor_partida_doble.dart';
import 'package:fiscogest_rd/core/contabilidad/data/repositories/periodo_fiscal_repository_impl.dart';
import 'package:fiscogest_rd/core/contabilidad/domain/repositories/i_periodo_fiscal_repository.dart';
import 'package:fiscogest_rd/core/contabilidad/domain/config/contabilidad_pais_config.dart';
import 'package:fiscogest_rd/core/contabilidad/domain/services/contabilidad_eventos_listener.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/features/almacenes/data/dao/stock_almacen_dao.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/ventas_dao.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/cuentas_cobrar_dao.dart';
import 'package:fiscogest_rd/features/ventas/data/repositories/ventas_repository_impl.dart';
import 'package:fiscogest_rd/features/ventas/data/services/venta_inventario_service_impl.dart';
import 'package:fiscogest_rd/features/ventas/domain/services/i_venta_inventario_service.dart';
import 'package:fiscogest_rd/features/apartados/data/repositories/apartado_repository_impl.dart';
import 'package:fiscogest_rd/features/devoluciones/data/repositories/devolucion_repository_impl.dart';
import 'package:fiscogest_rd/features/caja/data/repositories/caja_repository_impl.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/apartados_dao.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/devoluciones_dao.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/caja_movimientos_dao.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/caja_sesiones_dao.dart';
import 'package:fiscogest_rd/features/inventario/data/dao/productos_dao.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/ofertas_dao.dart';
import 'package:fiscogest_rd/features/inventario/data/datasources/drift_kardex_datasource.dart';
import 'package:fiscogest_rd/features/inventario/data/repositories/kardex_repository_impl.dart';
import 'package:fiscogest_rd/features/inventario/data/services/inventario_service_impl.dart';
import 'package:fiscogest_rd/features/inventario/domain/interfaces/ikardex_repository.dart';
import 'package:fiscogest_rd/features/inventario/domain/services/i_inventario_service.dart';
import 'package:fiscogest_rd/core/contabilidad/data/seed/plan_cuentas_rd_seed.dart';
import 'package:fiscogest_rd/core/contabilidad/data/config/plantilla_json_loader.dart';
import 'package:fiscogest_rd/features/comercial/domain/services/compra_eventos_listener.dart';

class RepositoryInjection {
  RepositoryInjection._({
    required this.db,
    required this.ventasRepository,
    required this.apartadoRepository,
    required this.devolucionRepository,
    required this.cajaRepository,
    required this.kardexRepository,
    required this.inventarioService,
    required this.productosDao,
    required this.ventaInventarioService,
    required this.planCuentasRepository,
    required this.asientoRepository,
    required this.motorPartidaDoble,
    required this.periodoFiscalRepository,
  });

  static RepositoryInjection? _instance;
  static CompraEventosListener? _compraEventosListener;
  static ContabilidadEventosListener? _contabilidadEventosListener;

  static RepositoryInjection get instance {
    if (_instance == null) {
      throw Exception('RepositoryInjection no inicializado');
    }
    return _instance!;
  }

  final AppDatabase db;
  final VentasRepositoryImpl ventasRepository;
  final ApartadoRepositoryImpl apartadoRepository;
  final DevolucionRepositoryImpl devolucionRepository;
  final CajaRepositoryImpl cajaRepository;
  final IKardexRepository kardexRepository;
  final IInventarioService inventarioService;
  final ProductosDao productosDao;
  final IVentaInventarioService ventaInventarioService;
  final IPlanCuentasRepository planCuentasRepository;
  final IAsientoRepository asientoRepository;
  final MotorPartidaDoble motorPartidaDoble;
  final IPeriodoFiscalRepository periodoFiscalRepository;

  static Future<RepositoryInjection> initialize(AppDatabase db) async {
    if (_instance != null) return _instance!;
    final apartadosDao = ApartadosDao(db);
    final devolucionesDao = DevolucionesDao(db);
    final cajaMovimientosDao = CajaMovimientosDao(db);
    final cajaSesionesDao = CajaSesionesDao(db);
    final productosDao = ProductosDao(db);
    final kardexDatasource = DriftKardexDatasource(db);
    final kardexRepo = KardexRepositoryImpl(kardexDatasource);
    final inventarioService = InventarioServiceImpl(db);
    final ventasDao = VentasDao(db);
    final cuentasCobrarDao = CuentasCobrarDao(db);
    final ventasRepository = VentasRepositoryImpl(
      ventasDao,
      cuentasCobrarDao,
      productosDao,
      OfertasDao(db),
    );
    final stockAlmacenDaoInst = StockAlmacenDao(db);
    final ventaInventarioService = VentaInventarioServiceImpl(
      ventasRepository: ventasRepository,
      kardexRepository: kardexRepo,
      inventarioService: inventarioService,
      productosDao: productosDao,
      stockAlmacenDao: stockAlmacenDaoInst,
    );
    final apartadoRepository = ApartadoRepositoryImpl(
      apartadosDao: apartadosDao,
    );
    final devolucionRepository = DevolucionRepositoryImpl(
      devolucionesDao: devolucionesDao,
    );
    final cajaRepository = CajaRepositoryImpl(
      cajaMovimientosDao: cajaMovimientosDao,
      cajaSesionesDao: cajaSesionesDao,
    );
    final planCuentasRepository = PlanCuentasRepositoryImpl(db);
    final asientoRepository = AsientoRepositoryImpl(db);
    final periodoFiscalRepository = PeriodoFiscalRepositoryImpl(db);
    // Plan + periodo del país activo (DO/MX/PR). Idempotente.
    // Plantilla del país: JSON en assets; fallback catálogo Dart.
    final plantilla =
        await PlantillaJsonLoader.cargar(ContabilidadPaisConfig.paisCodigo);
    ContabilidadPaisConfig.setPlantilla(plantilla);

    await PlanCuentasRdSeed(planCuentasRepository).asegurarPlanMinimo();
    await periodoFiscalRepository.asegurarPeriodoAnualActual(
      ContabilidadPaisConfig.paisCodigo,
    );
    // Seam de licencia: verificarLicencia se inyecta al cablear licencia_service.dart.
    // Seam licencia: fail-closed vía permiteContabilidad.
    final motorPartidaDoble = MotorPartidaDoble(
      asientoRepository,
      planCuentas: planCuentasRepository,
      periodos: periodoFiscalRepository,
      verificarLicencia: () async {
        try {
          final info = await LicenciaService(db).obtenerActual();
          return LicenciaGates(info).permiteContabilidad;
        } catch (_) {
          return false;
        }
      },
    );
    _compraEventosListener = CompraEventosListener();
    _contabilidadEventosListener = ContabilidadEventosListener(
      motor: motorPartidaDoble,
      planCuentas: planCuentasRepository,
    );

    _instance = RepositoryInjection._(
      db: db,
      ventasRepository: ventasRepository,
      apartadoRepository: apartadoRepository,
      devolucionRepository: devolucionRepository,
      cajaRepository: cajaRepository,
      kardexRepository: kardexRepo,
      inventarioService: inventarioService,
      productosDao: productosDao,
      ventaInventarioService: ventaInventarioService,
      planCuentasRepository: planCuentasRepository,
      asientoRepository: asientoRepository,
      motorPartidaDoble: motorPartidaDoble,
      periodoFiscalRepository: periodoFiscalRepository,
    );
    return _instance!;
  }

  static void dispose() {
    _compraEventosListener?.dispose();
    _contabilidadEventosListener?.dispose();
    _compraEventosListener = null;
    _contabilidadEventosListener = null;
    _instance = null;
  }
}
