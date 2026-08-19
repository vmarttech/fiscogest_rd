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
    throw UnimplementedError(
      'Agregar en CotizacionesDao: Future<void> marcarConvertida(int cotizacionId, int ventaId). '
      'Una vez exista, inserta la venta, llama al método y retorna la instancia Venta.'
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
    throw UnimplementedError(
      'DevolucionesDao: método insertarDevolucion aún no implementado. '
      'Agregar al DAO: Future<int> insertarDevolucion(DevolucionesTableCompanion data).'
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
    throw UnimplementedError(
      'CuentasCobrarDao no implementa consultar saldo por cliente. '
      'Agregar: Future<double?> obtenerSaldoPorCliente(int clienteId).'
    );
  }

  @override
  Future<List<Descuento>> obtenerDescuentosActivos() async {
    throw UnimplementedError(
      'DescuentosDao: método listarDescuentosActivos aún no implementado.'
    );
  }

  @override
  Future<List<Oferta>> obtenerOfertasActivas() async {
    throw UnimplementedError(
      'OfertasDao: método listarOfertasActivas aún no implementado.'
    );
  }

  @override
  Future<bool> aplicarDescuento(int ventaId, int descuentoId) async {
    throw UnimplementedError(
      'DescuentosDao: método aplicarDescuento aún no implementado.'
    );
  }

  @override
  Future<bool> validarOferta(int ofertaId, double montoCompra) async {
    throw UnimplementedError(
      'OfertasDao: método validarOferta aún no implementado.'
    );
  }

  @override
  Future<void> actualizarEnCascada(int ventaId) async {
    throw UnimplementedError(
      'Actualización en cascada: lógica pendiente. '
      'Implementar: actualizar inventario, kardex, saldos y estadísticas tras registrar venta.'
    );
  }
}
