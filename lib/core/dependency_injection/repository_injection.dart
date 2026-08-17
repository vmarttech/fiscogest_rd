// Registro de repositorios para la inyección de dependencias
import 'package:fiscogest_rd/core/database/app_database.dart';

// ====== REPOSITORIOS EXISTENTES =====
import 'package:fiscogest_rd/features/inventario/domain/interfaces/i_existencia_repository.dart';
import 'package:fiscogest_rd/features/inventario/data/repositories/existencia_repository_impl.dart';

// ====== DAOs - FASE 4 ======
import 'package:fiscogest_rd/features/comercial/data/dao/ventas_dao.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/cotizaciones_dao.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/apartados_dao.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/devoluciones_dao.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/cuentas_cobrar_dao.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/cuentas_pagar_dao.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/descuentos_dao.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/ofertas_dao.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/kardex_comercial_dao.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/caja_movimientos_dao.dart';
import 'package:fiscogest_rd/features/proveedores/data/dao/proveedores_dao.dart';
import 'package:fiscogest_rd/features/seguridad/data/dao/usuarios_dao.dart';

// ====== REPOSITORIOS - FASE 4 ======
import 'package:fiscogest_rd/features/ventas/domain/repositories/i_ventas_repository.dart';
import 'package:fiscogest_rd/features/ventas/data/repositories/ventas_repository_impl.dart';
import 'package:fiscogest_rd/features/apartados/domain/repositories/i_apartado_repository.dart';
import 'package:fiscogest_rd/features/apartados/data/repositories/apartado_repository_impl.dart';
import 'package:fiscogest_rd/features/cotizaciones/domain/repositories/i_cotizacion_repository.dart';
import 'package:fiscogest_rd/features/cotizaciones/data/repositories/cotizacion_repository_impl.dart';
import 'package:fiscogest_rd/features/devoluciones/domain/repositories/i_devolucion_repository.dart';
import 'package:fiscogest_rd/features/devoluciones/data/repositories/devolucion_repository_impl.dart';
import 'package:fiscogest_rd/features/caja/domain/repositories/i_caja_repository.dart';
import 'package:fiscogest_rd/features/caja/data/repositories/caja_repository_impl.dart';

class RepositoryInjection {
  // ====== EXISTENTES ======
  static IExistenciaRepository? existenciaRepository;

  // ====== DAOs - FASE 4 ======
  static VentasDao? ventasDao;
  static CotizacionesDao? cotizacionesDao;
  static ApartadosDao? apartadosDao;
  static DevolucionesDao? devolucionesDao;
  static CuentasCobrarDao? cuentasCobrarDao;
  static CuentasPagarDao? cuentasPagarDao;
  static DescuentosDao? descuentosDao;
  static OfertasDao? ofertasDao;
  static KardexComercialDao? kardexComercialDao;
  static CajaMovimientosDao? cajaMovimientosDao;
  static ProveedoresDao? proveedoresDao;
  static UsuariosDao? usuariosDao;

  // ====== REPOSITORIOS - FASE 4 ======
  static IVentasRepository? ventasRepository;
  static IApartadoRepository? apartadoRepository;
  static ICotizacionRepository? cotizacionRepository;
  static IDevolucionRepository? devolucionRepository;
  static ICajaRepository? cajaRepository;

  static void register(AppDatabase db) {
    // ====== REPOSITORIO EXISTENCIAS - ETAPA 3.1 ======
    existenciaRepository = ExistenciaRepositoryImpl(db);

    // ====== DAOs - FASE 4 ======
    ventasDao = VentasDao(db);
    cotizacionesDao = CotizacionesDao(db);
    apartadosDao = ApartadosDao(db);
    devolucionesDao = DevolucionesDao(db);
    cuentasCobrarDao = CuentasCobrarDao(db);
    cuentasPagarDao = CuentasPagarDao(db);
    descuentosDao = DescuentosDao(db);
    ofertasDao = OfertasDao(db);
    kardexComercialDao = KardexComercialDao(db);
    cajaMovimientosDao = CajaMovimientosDao(db);
    proveedoresDao = ProveedoresDao(db);
    usuariosDao = UsuariosDao(db);

    // ====== REPOSITORIOS - FASE 4 ======
    ventasRepository = VentasRepositoryImpl(
      ventasDao: ventasDao!,
      cotizacionesDao: cotizacionesDao!,
      apartadosDao: apartadosDao!,
      devolucionesDao: devolucionesDao!,
      cuentasCobrarDao: cuentasCobrarDao!,
      descuentosDao: descuentosDao!,
      ofertasDao: ofertasDao!,
    );

    apartadoRepository = ApartadoRepositoryImpl(apartadosDao!);
    cotizacionRepository = CotizacionRepositoryImpl(cotizacionesDao!);
    devolucionRepository = DevolucionRepositoryImpl(devolucionesDao!);
    cajaRepository = CajaRepositoryImpl(cajaMovimientosDao!);
  }
}
