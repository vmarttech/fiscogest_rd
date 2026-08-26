import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/cuentas_cobrar_dao.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/ventas_dao.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/venta.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/apartado.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/devolucion.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/pago.dart';
import 'package:fiscogest_rd/features/comercial/domain/entities/descuento.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/oferta.dart';
import 'package:fiscogest_rd/features/ventas/domain/repositories/i_ventas_repository.dart';
import 'package:fiscogest_rd/features/comercial/data/enums/comercial_enums.dart';
import 'package:drift/drift.dart';

class VentasRepositoryImpl implements IVentasRepository {

  VentasRepositoryImpl(this._ventasDao, this._cuentasCobrarDao);
  final VentasDao _ventasDao;
  final CuentasCobrarDao _cuentasCobrarDao;

  @override
  Future<List<Venta>> listarVentas({
    DateTime? desde,
    DateTime? hasta,
    int? clienteId,
    int? usuarioId,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<List<Venta>> listarCotizaciones({
    DateTime? desde,
    DateTime? hasta,
    int? clienteId,
    int? usuarioId,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<Venta?> obtenerVentaPorId(int ventaId) async {
    throw UnimplementedError();
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

    if (venta.esCredito) {
      final fechaVencimiento = venta.fecha.add(const Duration(days: 30));
      await _cuentasCobrarDao.crearCuentaPorVenta(
        clienteId: venta.clienteId,
        ventaId: ventaId,
        montoOriginal: venta.total,
        fechaVencimiento: fechaVencimiento,
      );
    }

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
  Future<Venta> registrarVentaBorrador(Venta cotizacion) async {
    final ventaId = await _ventasDao.insertarVenta(VentasTableCompanion(
      clienteId: Value(cotizacion.clienteId),
      fecha: Value(cotizacion.fecha),
      montoSubtotal: Value(cotizacion.subtotal),
      descuentoGlobal: Value(cotizacion.montoDescuento),
      itbis: Value(cotizacion.itbis),
      montoTotal: Value(cotizacion.total),
      formaPago: Value(FormaPago.values.firstWhere(
        (e) => e.name == cotizacion.tipoPago,
        orElse: () => FormaPago.efectivo,
      )),
      usuarioId: Value(cotizacion.usuarioId ?? 0),
      fechaRegistro: Value(cotizacion.createdAt ?? DateTime.now()),
    ));
    return Venta(
      id: ventaId,
      numero: ventaId.toString(),
      clienteId: cotizacion.clienteId,
      nombreCliente: cotizacion.nombreCliente,
      fecha: cotizacion.fecha,
      detalles: cotizacion.detalles,
      subtotal: cotizacion.subtotal,
      itbis: cotizacion.itbis,
      total: cotizacion.total,
      tipoPago: cotizacion.tipoPago,
      esCredito: cotizacion.esCredito,
      cotizacionOrigenId: cotizacion.cotizacionOrigenId,
      apartadoOrigenId: cotizacion.apartadoOrigenId,
      usuarioId: cotizacion.usuarioId,
      createdAt: cotizacion.createdAt,
      descuentoId: cotizacion.descuentoId,
      descuentoNombre: cotizacion.descuentoNombre,
      montoDescuento: cotizacion.montoDescuento,
    );
  }

  @override
  Future<Venta?> obtenerVentaBorradorPorId(int cotizacionId) async {
    throw UnimplementedError();
  }

  @override
  Future<Venta> actualizarVentaBorrador(Venta cotizacion) async {
    throw UnimplementedError();
  }

  @override
  Future<Venta> confirmarVentaBorrador(int cotizacionId) async {
    throw UnimplementedError();
  }

  @override
  Future<Apartado> registrarApartado(Apartado apartado) async {
    throw UnimplementedError();
  }

  @override
  Future<Devolucion> registrarDevolucion(Devolucion devolucion) async {
    throw UnimplementedError();
  }

  @override
  Future<Pago> registrarPago(Pago pago) async {
    throw UnimplementedError();
  }

  @override
  Future<double> consultarSaldoCliente(int clienteId) async {
    final saldo = await _cuentasCobrarDao.obtenerSaldoPorCliente(clienteId);
    return saldo ?? 0.0;
  }

  @override
  Future<List<Descuento>> obtenerDescuentosActivos() async {
    throw UnimplementedError();
  }

  @override
  Future<List<Oferta>> obtenerOfertasActivas() async {
    throw UnimplementedError();
  }

  @override
  Future<bool> aplicarDescuento(int ventaId, int descuentoId) async {
    throw UnimplementedError();
  }

  @override
  Future<bool> validarOferta(int ofertaId, double montoCompra) async {
    throw UnimplementedError();
  }

  @override
  Future<void> actualizarEnCascada(int ventaId) async {
    throw UnimplementedError();
  }
}
