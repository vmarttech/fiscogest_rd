import 'package:drift/drift.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/ventas_dao.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/cotizaciones_dao.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/apartados_dao.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/devoluciones_dao.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/cuentas_cobrar_dao.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/descuentos_dao.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/ofertas_dao.dart';
import 'package:fiscogest_rd/features/comercial/data/enums/comercial_enums.dart';
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
    final companion = VentasTableCompanion(
      clienteId: Value(venta.clienteId),
      fecha: Value(venta.fecha),
      montoTotal: Value(venta.total),
    );
    final idGenerado = await ventasDao.insertarVenta(companion);
    return Venta(
      id: idGenerado,
      numero: venta.numero,
      clienteId: venta.clienteId,
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
      convertidaAVenta: true,
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
    final companion = VentasTableCompanion(
      clienteId: Value(cotizacion.clienteId),
      fecha: Value(DateTime.now()),
      montoTotal: Value(cotizacion.montoTotal),
    );
    final ventaId = await ventasDao.insertarVenta(companion);
    await cotizacionesDao.marcarComoConvertida(cotizacionId, ventaId);
    return Venta(
      id: ventaId,
      numero: 'VTA-$ventaId',
      clienteId: cotizacion.clienteId,
      fecha: DateTime.now(),
      detalles: const [],
      subtotal: cotizacion.montoTotal * 0.87,
      itbis: cotizacion.itbis,
      total: cotizacion.montoTotal,
      tipoPago: 'Crédito',
      esCredito: true,
      cotizacionOrigenId: cotizacionId,
    );
  }

  @override
  Future<Apartado> registrarApartado(Apartado apartado) async {
    final estadoEnum = ApartadoEstado.values.firstWhere(
      (ApartadoEstado e) => e.name == apartado.estado.toLowerCase(),
      orElse: () => ApartadoEstado.reservado,
    );
    final companion = ApartadosTableCompanion(
      clienteId: Value(apartado.clienteId),
      fechaReserva: Value(apartado.fechaApartado),
      fechaLimite: Value(apartado.fechaLimitePago ?? apartado.fechaApartado.add(const Duration(days: 30))),
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
    throw UnimplementedError('registrarDevolucion: pendiente');
  }

  @override
  Future<Pago> registrarPago(Pago pago) async {
    final actualizado = await apartadosDao.actualizarSaldo(
      pago.cuentaCobrarId,
      pago.monto,
      0.0,
    );
    if (!actualizado) {
      throw Exception('Apartado no encontrado al registrar pago');
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
    throw UnimplementedError('consultarSaldoCliente: pendiente');
  }

  @override
  Future<List<Descuento>> obtenerDescuentosActivos() async {
    throw UnimplementedError('obtenerDescuentosActivos: pendiente');
  }

  @override
  Future<List<Oferta>> obtenerOfertasActivas() async {
    throw UnimplementedError('obtenerOfertasActivas: pendiente');
  }

  @override
  Future<bool> aplicarDescuento(int ventaId, int descuentoId) async {
    throw UnimplementedError('aplicarDescuento: pendiente');
  }

  @override
  Future<bool> validarOferta(int ofertaId, double montoCompra) async {
    throw UnimplementedError('validarOferta: pendiente');
  }

  @override
  Future<void> actualizarEnCascada(int ventaId) async {
    throw UnimplementedError('actualizarEnCascada: pendiente');
  }
}
