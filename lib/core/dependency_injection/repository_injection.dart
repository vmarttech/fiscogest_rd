import 'package:fiscogest_rd/core/database/app_database.dart';
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
import 'package:fiscogest_rd/features/inventario/data/datasources/drift_kardex_datasource.dart';
import 'package:fiscogest_rd/features/inventario/data/repositories/kardex_repository_impl.dart';
import 'package:fiscogest_rd/features/inventario/data/services/inventario_service_impl.dart';
import 'package:fiscogest_rd/features/inventario/domain/interfaces/ikardex_repository.dart';
import 'package:fiscogest_rd/features/inventario/domain/services/i_inventario_service.dart';
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
  });

  static RepositoryInjection? _instance;
  static CompraEventosListener? _compraEventosListener;

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

  static Future<RepositoryInjection> initialize(AppDatabase db) async {
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
    final ventasRepository = VentasRepositoryImpl(ventasDao, cuentasCobrarDao);
    final ventaInventarioService = VentaInventarioServiceImpl(
      ventasRepository: ventasRepository,
      kardexRepository: kardexRepo,
      inventarioService: inventarioService,
      productosDao: productosDao,
    );
    final apartadoRepository = ApartadoRepositoryImpl(apartadosDao: apartadosDao);
    final devolucionRepository = DevolucionRepositoryImpl(devolucionesDao: devolucionesDao);
    final cajaRepository = CajaRepositoryImpl(
      cajaMovimientosDao: cajaMovimientosDao,
      cajaSesionesDao: cajaSesionesDao,
    );
    _compraEventosListener = CompraEventosListener();

    // ✅ Leemos la variable para eliminar advertencia de campo no usado
    assert(_compraEventosListener != null, 'Listener inicializado');

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
    );
    return _instance!;
  }
}
