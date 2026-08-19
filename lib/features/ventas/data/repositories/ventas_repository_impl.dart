import 'package:drift/drift.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/features/comercial/data/enums/comercial_enums.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/ventas_dao.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/cotizaciones_dao.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/apartados_dao.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/devoluciones_dao.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/cuentas_cobrar_dao.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/descuentos_dao.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/ofertas_dao.dart';
import 'package:fiscogest_rd/features/inventario/data/dao/productos_dao.dart';
import 'package:fiscogest_rd/features/inventario/data/dao/existencias_dao.dart';
import 'package:fiscogest_rd/features/inventario/data/dao/salidas_dao.dart';
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
    required this.productosDao,
    required this.existenciasDao,
    required this.salidasDao,
  });

  final VentasDao ventasDao;
  final CotizacionesDao cotizacionesDao;
  final ApartadosDao apartadosDao;
  final DevolucionesDao devolucionesDao;
  final CuentasCobrarDao cuentasCobrarDao;
  final DescuentosDao descuentosDao;
  final OfertasDao ofertasDao;
  final ProductosDao productosDao;
  final ExistenciasDao existenciasDao;
  final SalidasDao salidasDao;

  @override
  Future<List<Map<String, dynamic>>> listarVentas({
    DateTime? desde,
    DateTime? hasta,
    int? clienteId,
    int? usuarioId,
  }) async {
    return ventasDao.listarVentas(
      desde: desde,
      hasta: hasta,
      clienteId: clienteId,
      usuarioId: usuarioId,
    );
  }

  @override
  Future<List<Map<String, dynamic>>> listarCotizaciones() async {
    return cotizacionesDao.listarCotizaciones();
  }

  @override
  Future<List<Map<String, dynamic>>> listarApartados() async {
    return apartadosDao.listarApartados();
  }

  @override
  Future<Venta> registrarVenta(Venta venta) async {
    final formaPagoEnum = FormaPago.values.firstWhere(
      (e) => e.name == venta.tipoPago || e.name.toLowerCase() == venta.tipoPago.toLowerCase(),
      orElse: () => FormaPago.efectivo,
    );

    final companion = VentasTableCompanion(
      clienteId: Value(venta.clienteId),
      usuarioId: Value(venta.usuarioId),
      fecha: Value(venta.fecha),
      montoSubtotal: Value(venta.subtotal),
      itbis: Value(venta.itbis),
      montoTotal: Value(venta.total),
      formaPago: Value(formaPagoEnum),
    );

    final idGenerado = await ventasDao.insertarVenta(companion);
    return Venta(
      id: idGenerado,
      numero: venta.numero,
      clienteId: venta.clienteId,
      usuarioId: venta.usuarioId,
      fecha: venta.fecha,
      detalles: venta.detalles,
      subtotal: venta.subtotal,
      itbis: venta.itbis,
      total: venta.total,
      tipoPago: venta.tipoPago,
      esCredito: venta.esCredito,
      cotizacionOrigenId: venta.cotizacionOrigenId,
      apartadoOrigenId: venta.apartadoOrigenId,
      createdAt: venta.createdAt ?? DateTime.now(),
      updatedAt: venta.updatedAt,
    );
  }

  @override
  Future<Cotizacion> registrarCotizacion(Cotizacion cotizacion) async {
    final companion = CotizacionesTableCompanion(
      clienteId: Value(cotizacion.clienteId),
      fechaEmision: Value(cotizacion.fechaEmision),
      fechaVigencia: Value(cotizacion.fechaVencimiento),
      montoSubtotal: Value(cotizacion.subtotal),
      itbis: Value(cotizacion.itbis),
      montoTotal: Value(cotizacion.total),
    );
    final idGenerado = await cotizacionesDao.insertarCotizacion(companion);
    return Cotizacion(
      id: idGenerado,
      numero: cotizacion.numero,
      clienteId: cotizacion.clienteId,
      fechaEmision: cotizacion.fechaEmision,
      fechaVencimiento: cotizacion.fechaVencimiento,
      detalles: cotizacion.detalles,
      subtotal: cotizacion.subtotal,
      itbis: cotizacion.itbis,
      total: cotizacion.total,
      convertidaAVenta: false,
      ventaId: null,
      createdAt: cotizacion.createdAt ?? DateTime.now(),
    );
  }

  @override
  Future<Venta> convertirCotizacionAVenta(int cotizacionId) async {
    final cotizacion = await cotizacionesDao.buscarPorId(cotizacionId);
    if (cotizacion == null) {
      throw Exception('Cotización con ID $cotizacionId no encontrada');
    }
    final ventaCompanion = VentasTableCompanion(
      clienteId: Value(cotizacion.clienteId),
      usuarioId: const Value.absent(),
      fecha: Value(DateTime.now()),
      montoSubtotal: Value(cotizacion.montoTotal * 0.84),
      itbis: Value(cotizacion.montoTotal * 0.16),
      montoTotal: Value(cotizacion.montoTotal),
      formaPago: const Value(FormaPago.efectivo),
    );
    final ventaId = await ventasDao.insertarVenta(ventaCompanion);
    await cotizacionesDao.marcarComoConvertida(cotizacionId, ventaId);
    return Venta(
      id: ventaId,
      numero: 'V-$ventaId',
      clienteId: cotizacion.clienteId,
      usuarioId: 0,
      fecha: DateTime.now(),
      detalles: const [],
      subtotal: cotizacion.montoTotal * 0.84,
      itbis: cotizacion.montoTotal * 0.16,
      total: cotizacion.montoTotal,
      tipoPago: 'efectivo',
      esCredito: false,
      cotizacionOrigenId: cotizacionId,
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<Apartado> registrarApartado(Apartado apartado) async {
    final estadoEnum = ApartadoEstado.values.byName(apartado.estado);
    final companion = ApartadosTableCompanion(
      clienteId: Value(apartado.clienteId),
      montoTotal: Value(apartado.montoTotal),
      montoAbonado: Value(apartado.montoAbonado),
      saldoPendiente: Value(apartado.saldoPendiente),
      estado: Value(estadoEnum),
    );
    final idGenerado = await apartadosDao.insertarApartado(companion);
    return Apartado(
      id: idGenerado,
      numero: apartado.numero,
      clienteId: apartado.clienteId,
      productos: apartado.productos,
      montoTotal: apartado.montoTotal,
      montoAbonado: apartado.montoAbonado,
      saldoPendiente: apartado.saldoPendiente,
      fechaApartado: apartado.fechaApartado,
      fechaLimitePago: apartado.fechaLimitePago,
      estado: apartado.estado,
      createdAt: apartado.createdAt ?? DateTime.now(),
    );
  }

  @override
  Future<Devolucion> registrarDevolucion(Devolucion devolucion) async {
    final estadoEnum = DevolucionEstado.values.byName(devolucion.estado);
    final companion = DevolucionesTableCompanion(
      ventaId: Value(devolucion.ventaId),
      fecha: Value(devolucion.fecha),
      motivo: Value(devolucion.motivo),
      tipo: const Value(DevolucionTipo.parcial),
      montoDevuelto: Value(devolucion.montoReembolsado),
      estado: Value(estadoEnum),
      afectaInventario: const Value(true),
      afectaCaja: const Value(true),
    );
    final idGenerado = await devolucionesDao.insertarDevolucion(companion);
    return Devolucion(
      id: idGenerado,
      numero: devolucion.numero,
      ventaId: devolucion.ventaId,
      productoId: devolucion.productoId,
      cantidadDevuelta: devolucion.cantidadDevuelta,
      montoReembolsado: devolucion.montoReembolsado,
      motivo: devolucion.motivo,
      fecha: devolucion.fecha,
      estado: estadoEnum.name,
      createdAt: devolucion.createdAt ?? DateTime.now(),
    );
  }

  @override
  Future<Pago> registrarPago(Pago pago) async {
    final exito = await apartadosDao.actualizarSaldo(
      pago.cuentaCobrarId,
      pago.monto,
      0.0,
    );
    if (!exito) {
      throw Exception('No se pudo registrar el pago: ID de cuenta por cobrar no válido.');
    }
    return Pago(
      id: pago.id,
      cuentaCobrarId: pago.cuentaCobrarId,
      clienteId: pago.clienteId,
      fecha: pago.fecha,
      monto: pago.monto,
      formaPago: pago.formaPago,
      referencia: pago.referencia,
      observaciones: pago.observaciones,
      createdAt: pago.createdAt ?? DateTime.now(),
    );
  }

  @override
  Future<double> consultarSaldoCliente(int clienteId) async {
    final saldo = await cuentasCobrarDao.obtenerSaldoPorCliente(clienteId);
    return saldo ?? 0.0;
  }

  @override
  Future<List<Descuento>> obtenerDescuentosActivos() async {
    final datos = await descuentosDao.listarDescuentosActivos();
    return datos.map((d) => Descuento(
      id: d.id,
      nombre: d.nombre,
      tipo: d.tipo.name,
      valor: d.valor,
      aplicaA: d.aplicaA.name,
      referenciaId: d.referenciaId,
      vigenciaDesde: d.vigenciaDesde,
      vigenciaHasta: d.vigenciaHasta,
      estado: d.estado.name,
    )).toList();
  }

  @override
  Future<List<Oferta>> obtenerOfertasActivas() async {
    final datos = await ofertasDao.listarOfertasActivas();
    return datos.map((o) => Oferta(
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
    return descuentosDao.aplicarDescuento(ventaId, descuentoId);
  }

  @override
  Future<bool> validarOferta(int ofertaId, double montoCompra) async {
    return ofertasDao.validarOferta(ofertaId, montoCompra);
  }

  @override
  Future<void> actualizarEnCascada(int ventaId) async {
    final venta = await ventasDao.buscarPorId(ventaId);
    if (venta == null) throw Exception('Venta no encontrada');

    final detalle = await ventasDao.listarDetallePorVenta(ventaId);

    for (final linea in detalle) {
      await productosDao.descontarStock(linea.productoId, linea.cantidad);
      await existenciasDao.descontarExistencia(linea.productoId, linea.cantidad);
      await salidasDao.registrarSalida(
        productoId: linea.productoId,
        cantidad: linea.cantidad,
        motivo: 'Venta',
      );
    }

    final esCredito = venta.formaPago == FormaPago.credito;
    if (esCredito) {
      final fechaVencimiento = venta.fecha.add(const Duration(days: 30));
      await cuentasCobrarDao.crearCuentaPorVenta(
        clienteId: venta.clienteId,
        ventaId: ventaId,
        montoOriginal: venta.montoTotal,
        fechaVencimiento: fechaVencimiento,
      );
    }
  }
}
