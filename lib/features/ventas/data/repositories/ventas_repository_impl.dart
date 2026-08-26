import 'package:drift/drift.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/ventas_dao.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/cotizaciones_dao.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/apartados_dao.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/devoluciones_dao.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/descuentos_dao.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/ofertas_dao.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/cuentas_cobrar_dao.dart';
import 'package:fiscogest_rd/features/comercial/data/enums/comercial_enums.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/venta.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/apartado.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/devolucion.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/pago.dart';
import 'package:fiscogest_rd/features/comercial/domain/entities/descuento.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/oferta.dart';
import 'package:fiscogest_rd/features/ventas/domain/repositories/i_ventas_repository.dart';

class VentasRepositoryImpl implements IVentasRepository {

  VentasRepositoryImpl({AppDatabase? db}) : _db = db ?? AppDatabase() {
    _ventasDao = VentasDao(_db);
    _cotizacionesDao = CotizacionesDao(_db);
    _apartadosDao = ApartadosDao(_db);
    _devolucionesDao = DevolucionesDao(_db);
    _descuentosDao = DescuentosDao(_db);
    _ofertasDao = OfertasDao(_db);
    _cuentasCobrarDao = CuentasCobrarDao(_db);
  }
  final AppDatabase _db;
  late final VentasDao _ventasDao;
  late final CotizacionesDao _cotizacionesDao;
  late final ApartadosDao _apartadosDao;
  late final DevolucionesDao _devolucionesDao;
  late final DescuentosDao _descuentosDao;
  late final OfertasDao _ofertasDao;
  late final CuentasCobrarDao _cuentasCobrarDao;

  Venta _mapearVenta(VentaData fila, String? nombreCliente) {
    return Venta(
      id: fila.id,
      numero: fila.id.toString(),
      clienteId: fila.clienteId,
      nombreCliente: nombreCliente,
      fecha: fila.fecha,
      detalles: const [],
      subtotal: fila.montoSubtotal,
      itbis: fila.itbis,
      total: fila.montoTotal,
      tipoPago: fila.formaPago.name,
      esCredito: false,
      cotizacionOrigenId: null,
      apartadoOrigenId: null,
      usuarioId: fila.usuarioId,
      createdAt: fila.fechaRegistro,
      descuentoId: null,
      montoDescuento: fila.descuentoGlobal,
    );
  }

  @override
  Future<List<Venta>> listarVentas({
    DateTime? desde,
    DateTime? hasta,
    int? clienteId,
    int? usuarioId,
  }) async {
    final resultados = await _ventasDao.listarVentas(
      desde: desde,
      hasta: hasta,
      clienteId: clienteId,
      usuarioId: usuarioId,
    );
    return resultados
        .map((r) => _mapearVenta(r.venta, r.nombreCliente))
        .toList();
  }

  @override
  Future<Venta?> obtenerVentaPorId(int ventaId) async {
    final fila = await _ventasDao.obtenerVentaPorId(ventaId);
    if (fila == null) return null;
    return _mapearVenta(fila, null);
  }

  @override
  Future<Venta> registrarVenta(Venta venta) async {
    final ventaId = await _ventasDao.insertarVenta(VentasTableCompanion(
      clienteId: Value(venta.clienteId),
      fecha: Value(venta.fecha),
      montoSubtotal: Value(venta.subtotal),
      descuentoGlobal: Value(venta.montoDescuento),
      itbis: Value(venta.itbis),
      montoTotal: Value(venta.total),
      formaPago: Value(FormaPago.values.firstWhere(
        (e) => e.name == venta.tipoPago,
        orElse: () => FormaPago.efectivo,
      )),
      usuarioId: Value(venta.usuarioId ?? 0),
      fechaRegistro: Value(venta.createdAt ?? DateTime.now()),
    ));
    return Venta(
      id: ventaId,
      numero: ventaId.toString(),
      clienteId: venta.clienteId,
      nombreCliente: venta.nombreCliente,
      fecha: venta.fecha,
      detalles: venta.detalles,
      subtotal: venta.subtotal,
      itbis: venta.itbis,
      total: venta.total,
      tipoPago: venta.tipoPago,
      esCredito: venta.esCredito,
      cotizacionOrigenId: venta.cotizacionOrigenId,
      apartadoOrigenId: venta.apartadoOrigenId,
      usuarioId: venta.usuarioId,
      createdAt: venta.createdAt,
      descuentoId: venta.descuentoId,
      descuentoNombre: venta.descuentoNombre,
      montoDescuento: venta.montoDescuento,
    );
  }

  @override
  Future<List<Venta>> listarCotizaciones({
    DateTime? desde,
    DateTime? hasta,
    int? clienteId,
    int? usuarioId,
  }) async {
    final filas = await _cotizacionesDao.listarCotizaciones();
    return filas.map((json) {
      return Venta(
        id: json['id'] as int,
        numero: json['id'].toString(),
        clienteId: json['clienteId'] as int,
        fecha: json['fechaEmision'] as DateTime,
        detalles: const [],
        subtotal: (json['montoSubtotal'] as num).toDouble(),
        itbis: (json['itbis'] as num).toDouble(),
        total: (json['montoTotal'] as num).toDouble(),
        tipoPago: 'cotizacion',
        esCredito: false,
        cotizacionOrigenId: json['id'] as int,
        createdAt: json['fechaEmision'] as DateTime,
      );
    }).toList();
  }

  @override
  Future<Venta?> obtenerCotizacionPorId(int cotizacionId) async {
    final fila = await _cotizacionesDao.buscarPorId(cotizacionId);
    if (fila == null) return null;
    return Venta(
      id: fila.id,
      numero: fila.id.toString(),
      clienteId: fila.clienteId,
      fecha: fila.fechaEmision,
      detalles: const [],
      subtotal: fila.montoSubtotal,
      itbis: fila.itbis,
      total: fila.montoTotal,
      tipoPago: 'cotizacion',
      esCredito: false,
      cotizacionOrigenId: fila.id,
      createdAt: fila.fechaEmision,
    );
  }

  @override
  Future<Venta> registrarCotizacion(Venta cotizacion) async {
    final cotizacionId = await _cotizacionesDao.insertarCotizacion(CotizacionesTableCompanion(
      clienteId: Value(cotizacion.clienteId),
      fechaEmision: Value(cotizacion.fecha),
      fechaVigencia: Value(cotizacion.fecha.add(const Duration(days: 30))),
      montoSubtotal: Value(cotizacion.subtotal),
      descuentoGlobal: Value(cotizacion.montoDescuento),
      itbis: Value(cotizacion.itbis),
      montoTotal: Value(cotizacion.total),
      estado: const Value(CotizacionEstado.pendiente),
    ));
    return Venta(
      id: cotizacionId,
      numero: cotizacionId.toString(),
      clienteId: cotizacion.clienteId,
      fecha: cotizacion.fecha,
      detalles: cotizacion.detalles,
      subtotal: cotizacion.subtotal,
      itbis: cotizacion.itbis,
      total: cotizacion.total,
      tipoPago: 'cotizacion',
      esCredito: false,
      cotizacionOrigenId: cotizacionId,
      createdAt: cotizacion.fecha,
    );
  }

  @override
  Future<Venta> actualizarCotizacion(Venta cotizacion) async {
    throw UnimplementedError('Actualización de cotización requiere UPDATE en CotizacionesTable');
  }

  @override
  Future<Venta> convertirCotizacionAVenta(int cotizacionId) async {
    final cotizacion = await obtenerCotizacionPorId(cotizacionId);
    if (cotizacion == null) {
      throw Exception('Cotización $cotizacionId no encontrada');
    }
    final ventaGenerada = await registrarVenta(Venta(
      numero: '',
      clienteId: cotizacion.clienteId,
      fecha: DateTime.now(),
      detalles: cotizacion.detalles,
      subtotal: cotizacion.subtotal,
      itbis: cotizacion.itbis,
      total: cotizacion.total,
      tipoPago: cotizacion.tipoPago,
      esCredito: cotizacion.esCredito,
      cotizacionOrigenId: cotizacionId,
      usuarioId: cotizacion.usuarioId,
      createdAt: DateTime.now(),
    ));
    if (ventaGenerada.id == null) {
      throw Exception('No se pudo generar la venta desde cotización');
    }
    await _cotizacionesDao.marcarComoConvertida(cotizacionId, ventaGenerada.id!);
    return ventaGenerada;
  }

  @override
  Future<Apartado> registrarApartado(Apartado apartado) async {
    final apartadoId = await _apartadosDao.insertarApartado(ApartadosTableCompanion(
      clienteId: Value(apartado.clienteId),
      fechaReserva: Value(apartado.fechaApartado),
      fechaLimite: Value(apartado.fechaLimitePago ?? apartado.fechaApartado.add(const Duration(days: 30))),
      montoTotal: Value(apartado.montoTotal),
      montoAbonado: Value(apartado.montoAbonado),
      saldoPendiente: Value(apartado.saldoPendiente),
      estado: Value(ApartadoEstado.values.firstWhere(
        (e) => e.name == apartado.estado,
        orElse: () => ApartadoEstado.reservado,
      )),
    ));
    return Apartado(
      id: apartadoId,
      numero: apartadoId.toString(),
      clienteId: apartado.clienteId,
      productos: apartado.productos,
      montoTotal: apartado.montoTotal,
      montoAbonado: apartado.montoAbonado,
      saldoPendiente: apartado.saldoPendiente,
      fechaApartado: apartado.fechaApartado,
      fechaLimitePago: apartado.fechaLimitePago,
      estado: apartado.estado,
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<Devolucion> registrarDevolucion(Devolucion devolucion) async {
    final devolucionId = await _devolucionesDao.insertarDevolucion(DevolucionesTableCompanion(
      ventaId: Value(devolucion.ventaId),
      fecha: Value(devolucion.fecha),
      motivo: Value(devolucion.motivo),
      tipo: const Value(DevolucionTipo.parcial),
      montoDevuelto: Value(devolucion.montoReembolsado),
      estado: Value(DevolucionEstado.values.firstWhere(
        (e) => e.name == devolucion.estado,
        orElse: () => DevolucionEstado.registrada,
      )),
      afectaInventario: const Value(true),
      afectaCaja: const Value(false),
    ));
    return Devolucion(
      id: devolucionId,
      numero: devolucionId.toString(),
      ventaId: devolucion.ventaId,
      productoId: devolucion.productoId,
      cantidadDevuelta: devolucion.cantidadDevuelta,
      montoReembolsado: devolucion.montoReembolsado,
      motivo: devolucion.motivo,
      fecha: devolucion.fecha,
      estado: devolucion.estado,
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<Pago> registrarPago(Pago pago) async {
    throw UnimplementedError('RegistrarPago: requiere CobrosDao y CuentasCobrarDao');
  }

  @override
  Future<double> consultarSaldoCliente(int clienteId) async {
    final saldo = await _cuentasCobrarDao.obtenerSaldoPorCliente(clienteId);
    return saldo ?? 0.0;
  }

  @override
  Future<List<Descuento>> obtenerDescuentosActivos() async {
    final filas = await _descuentosDao.listarDescuentosActivos();
    return filas.map((d) => Descuento(
      id: d.id.toString(),
      tipo: TipoDescuento.porProducto,
      valor: d.valor,
      motivo: 'Descuento vigente',
      estadoAutorizacion: EstadoAutorizacion.requierePermiso,
      fechaRegistro: d.vigenciaDesde,
      productoId: d.referenciaId?.toString(),
    )).toList();
  }

  @override
  Future<List<Oferta>> obtenerOfertasActivas() async {
    final filas = await _ofertasDao.listarOfertasActivas();
    return filas.map((o) => Oferta(
      id: o.id,
      nombre: o.nombre,
      productoId: o.productoId,
      cantidadMinima: o.cantidadMinima,
      precioOferta: o.precioOferta,
      vigenciaDesde: o.vigenciaDesde,
      vigenciaHasta: o.vigenciaHasta,
      estado: o.estado.name,
    )).toList();
  }

  @override
  Future<bool> aplicarDescuento(int ventaId, int descuentoId) async {
    return await _descuentosDao.aplicarDescuento(ventaId, descuentoId);
  }

  @override
  Future<bool> validarOferta(int ofertaId, double montoCompra) async {
    return await _ofertasDao.validarOferta(ofertaId, montoCompra);
  }

  @override
  Future<void> actualizarEnCascada(int ventaId) async {
    final venta = await obtenerVentaPorId(ventaId);
    if (venta == null) return;
  }
}
