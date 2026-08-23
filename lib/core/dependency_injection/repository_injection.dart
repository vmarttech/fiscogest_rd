import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/features/ventas/data/repositories/ventas_repository_impl.dart';
import 'package:fiscogest_rd/features/ventas/data/services/venta_inventario_service_impl.dart';
import 'package:fiscogest_rd/features/ventas/domain/services/i_venta_inventario_service.dart';
import 'package:fiscogest_rd/features/apartados/data/repositories/apartado_repository_impl.dart';
import 'package:fiscogest_rd/features/cotizaciones/data/repositories/cotizacion_repository_impl.dart';
import 'package:fiscogest_rd/features/devoluciones/data/repositories/devolucion_repository_impl.dart';
import 'package:fiscogest_rd/features/caja/data/repositories/caja_repository_impl.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/ventas_dao.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/cotizaciones_dao.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/apartados_dao.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/devoluciones_dao.dart';
import 'package:fiscogest_rd/features/inventario/data/dao/productos_dao.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/caja_movimientos_dao.dart';
import 'package:fiscogest_rd/features/inventario/data/datasources/drift_kardex_datasource.dart';
import 'package:fiscogest_rd/features/inventario/data/repositories/kardex_repository_impl.dart';
import 'package:fiscogest_rd/features/inventario/data/services/inventario_service_impl.dart';
import 'package:fiscogest_rd/features/inventario/domain/interfaces/ikardex_repository.dart';
import 'package:fiscogest_rd/features/inventario/domain/services/i_inventario_service.dart';

class RepositoryInjection {
  RepositoryInjection._({
    required this.db,
    required this.ventasRepository,
    required this.apartadoRepository,
    required this.cotizacionRepository,
    required this.devolucionRepository,
    required this.cajaRepository,
    required this.kardexRepository,
    required this.inventarioService,
    required this.productosDao,
    required this.ventaInventarioService,
  });

  static RepositoryInjection? _instance;
  static RepositoryInjection get instance {
    if (_instance == null) {
      throw Exception('RepositoryInjection no inicializado');
    }
    return _instance!;
  }

  final AppDatabase db;
  final VentasRepositoryImpl ventasRepository;
  final ApartadoRepositoryImpl apartadoRepository;
  final CotizacionRepositoryImpl cotizacionRepository;
  final DevolucionRepositoryImpl devolucionRepository;
  final CajaRepositoryImpl cajaRepository;
  final IKardexRepository kardexRepository;
  final IInventarioService inventarioService;
  final ProductosDao productosDao;
  final IVentaInventarioService ventaInventarioService;

  static Future<RepositoryInjection> initialize(AppDatabase db) async {
    final ventasDao = VentasDao(db);
    final cotizacionesDao = CotizacionesDao(db);
    final apartadosDao = ApartadosDao(db);
    final devolucionesDao = DevolucionesDao(db);
    final cajaMovimientosDao = CajaMovimientosDao(db);
    final productosDao = ProductosDao(db);
    final kardexDatasource = DriftKardexDatasource(db);
    final kardexRepository = KardexRepositoryImpl(kardexDatasource);
    final inventarioService = InventarioServiceImpl(db);

    final ventasRepository = VentasRepositoryImpl(ventasDao: ventasDao);

    final ventaInventarioService = VentaInventarioServiceImpl(
      ventasRepository: ventasRepository,
      kardexRepository: kardexRepository,
      inventarioService: inventarioService,
      productosDao: productosDao,
    );

    final apartadoRepository = ApartadoRepositoryImpl(
      apartadosDao: apartadosDao,
    );
    final cotizacionRepository = CotizacionRepositoryImpl(
      cotizacionesDao: cotizacionesDao,
    );
    final devolucionRepository = DevolucionRepositoryImpl(
      devolucionesDao: devolucionesDao,
    );
    final cajaRepository = CajaRepositoryImpl(
      cajaMovimientosDao: cajaMovimientosDao,
    );

    _instance = RepositoryInjection._(
      db: db,
      ventasRepository: ventasRepository,
      apartadoRepository: apartadoRepository,
      cotizacionRepository: cotizacionRepository,
      devolucionRepository: devolucionRepository,
      cajaRepository: cajaRepository,
      kardexRepository: kardexRepository,
      inventarioService: inventarioService,
      productosDao: productosDao,
      ventaInventarioService: ventaInventarioService,
    );
    return _instance!;
  }
}
