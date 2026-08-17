import 'package:drift/drift.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/ventas_dao.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/cotizaciones_dao.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/apartados_dao.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/devoluciones_dao.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/cuentas_cobrar_dao.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/descuentos_dao.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/ofertas_dao.dart';
import 'package:fiscogest_rd/features/comercial/data/mappers/venta_mapper.dart';
import 'package:fiscogest_rd/features/comercial/data/mappers/cotizacion_mapper.dart';
import 'package:fiscogest_rd/features/comercial/data/mappers/apartado_mapper.dart';
import 'package:fiscogest_rd/features/comercial/data/mappers/devolucion_mapper.dart';
import 'package:fiscogest_rd/features/comercial/data/mappers/pago_mapper.dart';
import 'package:fiscogest_rd/features/comercial/data/mappers/descuento_mapper.dart';
import 'package:fiscogest_rd/features/comercial/data/mappers/oferta_mapper.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/venta.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/cotizacion.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/apartado.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/devolucion.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/pago.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/descuento.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/oferta.dart';
import 'package:fiscogest_rd/features/ventas/domain/repositories/i_ventas_repository.dart';

class VentasRepositoryImpl implements IVentasRepository {
  VentasRepositoryImpl({
    required this.ventasDao,
    required this.cotizacionesDao,
    required this.apartadosDao,
    required this.devolucionesDao,
    required this.cuentasCobrarDao,
    required this.descuentosDao,
    required this.ofertasDao,
  });

  final VentasDao ventasDao;
  final CotizacionesDao cotizacionesDao;
  final ApartadosDao apartadosDao;
  final DevolucionesDao devolucionesDao;
  final CuentasCobrarDao cuentasCobrarDao;
  final DescuentosDao descuentosDao;
  final OfertasDao ofertasDao;

  @override
  Future<List<Map<String, dynamic>>> listarVentas({
    DateTime? desde,
    DateTime? hasta,
    int? clienteId,
    int? usuarioId,
  }) async {
    final filas = await ventasDao.listarPorFiltros(
      desde: desde,
      hasta: hasta,
      clienteId: clienteId,
      usuarioId: usuarioId,
    );
    return filas.map((f) => {
      'id': f.id,
      'clienteId': f.clienteId,
      'fecha': f.fecha.toIso8601String(),
      'subtotal': f.montoSubtotal,
      'itbis': f.itbis,
      'total': f.montoTotal,
      'formaPago': f.formaPago,
      'estado': f.estado,
      'usuarioId': f.usuarioId,
    }).toList();
  }

  @override
  Future<Venta> registrarVenta(Venta venta) async {
    const usuarioId = 1;
    final ventaCompanion = VentaDataMapper.toCompanion(venta, usuarioId);
    final detallesCompanion = venta.detalles
        .map((d) => VentaDataMapper.detalleToCompanion(d, 0))
        .toList();

    final ventaId = await ventasDao.registrarVentaCompleta(ventaCompanion, detallesCompanion);
    final ventaGuardada = await ventasDao.obtenerPorId(ventaId);
    final detallesGuardados = await ventasDao.obtenerDetallesPorVenta(ventaId);

    final detallesDominio = detallesGuardados
        .map((d) => VentaDataMapper.detalleToDomain(d, ''))
        .toList();

    return VentaDataMapper.toDomain(ventaGuardada!, detallesDominio);
  }

  @override
  Future<Cotizacion> registrarCotizacion(Cotizacion cotizacion) async {
    final cotizacionCompanion = CotizacionDataMapper.toCompanion(cotizacion);
    final detallesCompanion = cotizacion.detalles
        .map((d) => CotizacionDataMapper.detalleToCompanion(d, 0))
        .toList();

    final cotizacionId = await cotizacionesDao.registrarCotizacionCompleta(cotizacionCompanion, detallesCompanion);
    final cotizacionGuardada = await cotizacionesDao.obtenerPorId(cotizacionId);
    final detallesGuardados = await cotizacionesDao.obtenerDetallesPorCotizacion(cotizacionId);

    final detallesDominio = detallesGuardados
        .map((d) => DetalleVenta(
              productoId: d.productoId,
              nombreProducto: '',
              cantidad: d.cantidad,
              precioUnitario: d.precioUnitario,
              subtotalLinea: d.subtotal,
              montoDescuento: d.descuentoLinea > 0 ? d.descuentoLinea : null,
            ))
        .toList();

    return CotizacionDataMapper.toDomain(cotizacionGuardada!, detallesDominio);
  }

  @override
  Future<Venta> convertirCotizacionAVenta(int cotizacionId) async {
    final cotizacion = await cotizacionesDao.obtenerPorId(cotizacionId);
    if (cotizacion == null) throw Exception('Cotización no encontrada');

    final detalles = await cotizacionesDao.obtenerDetallesPorCotizacion(cotizacionId);

    const usuarioId = 1;
    final ventaCompanion = VentasTableCompanion(
      clienteId: Value(cotizacion.clienteId),
      fecha: Value(DateTime.now()),
      montoSubtotal: Value(cotizacion.montoSubtotal),
      descuentoGlobal: Value(cotizacion.descuentoGlobal),
      itbis: Value(cotizacion.itbis),
      montoTotal: Value(cotizacion.montoTotal),
      formaPago: const Value('Efectivo'),
      estado: const Value('Confirmada'),
      usuarioId: const Value(usuarioId),
    );

    final ventaDetallesCompanion = detalles
        .map((d) => VentasDetalleTableCompanion(
              ventaId: const Value(0),
              productoId: Value(d.productoId),
              cantidad: Value(d.cantidad),
              precioUnitario: Value(d.precioUnitario),
              descuentoLinea: Value(d.descuentoLinea),
              subtotal: Value(d.subtotal),
              impuesto: Value(d.subtotal * 0.18),
            ))
        .toList();

    final ventaId = await ventasDao.registrarVentaCompleta(ventaCompanion, ventaDetallesCompanion);
    await cotizacionesDao.marcarConvertida(cotizacionId, ventaId);

    final ventaGuardada = await ventasDao.obtenerPorId(ventaId);
    final detallesDominio = detalles
        .map((d) => DetalleVenta(
              productoId: d.productoId,
              nombreProducto: '',
              cantidad: d.cantidad,
              precioUnitario: d.precioUnitario,
              subtotalLinea: d.subtotal,
            ))
        .toList();

    return VentaDataMapper.toDomain(ventaGuardada!, detallesDominio);
  }

  @override
  Future<Apartado> registrarApartado(Apartado apartado) async {
    final apartadoCompanion = ApartadoDataMapper.toCompanion(apartado);
    final detallesCompanion = apartado.productos
        .map((p) => ApartadoDataMapper.detalleToCompanion(p, 0))
        .toList();

    final apartadoId = await apartadosDao.registrarApartadoCompleto(apartadoCompanion, detallesCompanion);
    final apartadoGuardado = await apartadosDao.obtenerPorId(apartadoId);
    final detallesGuardados = await apartadosDao.obtenerDetallesPorApartado(apartadoId);

    final productosDominio = detallesGuardados
        .map((d) => DetalleVenta(
              productoId: d.productoId,
              nombreProducto: '',
              cantidad: d.cantidad,
              precioUnitario: d.precioUnitario,
              subtotalLinea: d.subtotal,
            ))
        .toList();

    return ApartadoDataMapper.toDomain(apartadoGuardado!, productosDominio);
  }

  @override
  Future<Devolucion> registrarDevolucion(Devolucion devolucion) async {
    final devolucionCompanion = DevolucionDataMapper.toCompanion(devolucion);
    final detalleCompanion = DevolucionDataMapper.detalleToCompanion(devolucion, 0);

    final devolucionId = await devolucionesDao.registrarDevolucionCompleta(devolucionCompanion, [detalleCompanion]);
    final devolucionGuardada = await devolucionesDao.obtenerPorId(devolucionId);
    final detallesGuardados = await devolucionesDao.obtenerDetallesPorDevolucion(devolucionId);

    return DevolucionDataMapper.toDomain(devolucionGuardada!, detallesGuardados.firstOrNull);
  }

  @override
  Future<Pago> registrarPago(Pago pago) async {
    final cuenta = await cuentasCobrarDao.obtenerPorId(pago.cuentaCobrarId);
    if (cuenta == null) throw Exception('Cuenta por cobrar no encontrada');

    final nuevoAbonado = cuenta.montoAbonado + pago.monto;
    final nuevoSaldo = cuenta.saldoPendiente - pago.monto;
    final nuevoEstado = nuevoSaldo <= 0 ? 'Pagado' : (nuevoAbonado > 0 ? 'Parcial' : 'Pendiente');

    final cobroCompanion = PagoDataMapper.toCompanion(pago, cuenta.saldoPendiente, nuevoSaldo);
    await cuentasCobrarDao.aplicarCobro(pago.cuentaCobrarId, cobroCompanion, nuevoSaldo, nuevoAbonado, nuevoEstado);

    return pago;
  }

  @override
  Future<double> consultarSaldoCliente(int clienteId) async {
    final cuentas = await cuentasCobrarDao.listarPorCliente(clienteId);
    return cuentas.fold<double>(0, (sum, c) => sum + c.saldoPendiente);
  }

  @override
  Future<List<Descuento>> obtenerDescuentosActivos() async {
    final filas = await descuentosDao.obtenerVigentes(DateTime.now());
    return filas.map((f) => DescuentoDataMapper.toDomain(f)).toList();
  }

  @override
  Future<List<Oferta>> obtenerOfertasActivas() async {
    final filas = await ofertasDao.obtenerVigentes(DateTime.now());
    return filas.map((f) => OfertaDataMapper.toDomain(f)).toList();
  }

  @override
  Future<bool> aplicarDescuento(int ventaId, int descuentoId) async {
    return true;
  }

  @override
  Future<bool> validarOferta(int ofertaId, double montoCompra) async {
    final oferta = await ofertasDao.obtenerPorId(ofertaId);
    if (oferta == null) return false;
    if (oferta.estado != 'Vigente') return false;
    final ahora = DateTime.now();
    return ahora.isAfter(oferta.vigenciaDesde) && ahora.isBefore(oferta.vigenciaHasta);
  }

  @override
  Future<void> actualizarEnCascada(int ventaId) async {
    // TODO: Implementar actualización en cascada
  }
}
