import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/features/ventas/data/repositories/ventas_repository_impl.dart';
import 'package:fiscogest_rd/features/apartados/data/repositories/apartado_repository_impl.dart';
import 'package:fiscogest_rd/features/cotizaciones/data/repositories/cotizacion_repository_impl.dart';
import 'package:fiscogest_rd/features/devoluciones/data/repositories/devolucion_repository_impl.dart';
import 'package:fiscogest_rd/features/caja/data/repositories/caja_repository_impl.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/ventas_dao.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/cotizaciones_dao.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/apartados_dao.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/devoluciones_dao.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/cuentas_cobrar_dao.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/descuentos_dao.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/ofertas_dao.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/caja_movimientos_dao.dart';
import 'package:fiscogest_rd/features/inventario/data/dao/productos_dao.dart';
import 'package:fiscogest_rd/features/inventario/data/dao/existencias_dao.dart';
import 'package:fiscogest_rd/features/inventario/data/dao/salidas_dao.dart';

class RepositoryInjection {
  RepositoryInjection._({
    required this.ventasRepository,
    required this.apartadoRepository,
    required this.cotizacionRepository,
    required this.devolucionRepository,
    required this.cajaRepository,
  });

  static RepositoryInjection? _instance;

  static RepositoryInjection get instance {
    if (_instance == null) {
      throw Exception('RepositoryInjection no inicializado');
    }
    return _instance!;
  }

  final VentasRepositoryImpl ventasRepository;
  final ApartadoRepositoryImpl apartadoRepository;
  final CotizacionRepositoryImpl cotizacionRepository;
  final DevolucionRepositoryImpl devolucionRepository;
  final CajaRepositoryImpl cajaRepository;

  static Future<RepositoryInjection> initialize(AppDatabase db) async {
    final ventasDao = VentasDao(db);
    final cotizacionesDao = CotizacionesDao(db);
    final apartadosDao = ApartadosDao(db);
    final devolucionesDao = DevolucionesDao(db);
    final cuentasCobrarDao = CuentasCobrarDao(db);
    final descuentosDao = DescuentosDao(db);
    final ofertasDao = OfertasDao(db);
    final cajaMovimientosDao = CajaMovimientosDao(db);
    final productosDao = ProductosDao(db);
    final existenciasDao = ExistenciasDao(db);
    final salidasDao = SalidasDao(db);

    final ventasRepository = VentasRepositoryImpl(
      ventasDao: ventasDao,
      cotizacionesDao: cotizacionesDao,
      apartadosDao: apartadosDao,
      devolucionesDao: devolucionesDao,
      cuentasCobrarDao: cuentasCobrarDao,
      descuentosDao: descuentosDao,
      ofertasDao: ofertasDao,
      productosDao: productosDao,
      existenciasDao: existenciasDao,
      salidasDao: salidasDao,
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
      ventasRepository: ventasRepository,
      apartadoRepository: apartadoRepository,
      cotizacionRepository: cotizacionRepository,
      devolucionRepository: devolucionRepository,
      cajaRepository: cajaRepository,
    );

    return _instance!;
  }
}
