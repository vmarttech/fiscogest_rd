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
import 'package:fiscogest_rd/features/ventas/domain/enums/estado_documento.dart';
import 'package:drift/drift.dart';

class VentasRepositoryImpl implements IVentasRepository {
  VentasRepositoryImpl(this._ventasDao, this._cuentasCobrarDao);
  final VentasDao _ventasDao;
  final CuentasCobrarDao _cuentasCobrarDao;

  Venta _mapearDesdeDatos(
    VentasTableData ventaData,
    String? nombreCliente, {
    bool esCotizacion = false,
  }) {
    EstadoDocumento parsearEstado(String valor) => switch(valor) {
      'borrador' => EstadoDocumento.borrador,
      'cotizado' => EstadoDocumento.cotizado,
      'enCredito' => EstadoDocumento.enCredito,
      'aprobado' => EstadoDocumento.aprobado,
      'anulado' => EstadoDocumento.anulado,
      'facturado' => EstadoDocumento.facturado,
      _ => EstadoDocumento.borrador,
    };

    final estadoDoc = parsearEstado(ventaData.estadoDocumento);

    return Venta(
      id: ventaData.id,
      numeroCotizacion: ventaData.numeroCotizacion,
      numeroFactura: ventaData.numeroFactura,
      clienteId: ventaData.clienteId,
      nombreCliente: nombreCliente,
      fecha: ventaData.fecha,
      detalles: const [],
      montoSubtotal: ventaData.montoSubtotal,
      descuentoGlobal: ventaData.descuentoGlobal,
      itbis: ventaData.itbis,
      montoTotal: ventaData.montoTotal,
      formaPago: ventaData.formaPago,
      costoEnvio: ventaData.costoEnvio,
      abonoInicial: ventaData.abonoInicial,
      vencimiento: ventaData.vencimiento,
      estadoDocumento: estadoDoc,
      usuarioId: ventaData.usuarioId,
      fechaRegistro: ventaData.fechaRegistro,
      descuentoId: ventaData.descuentoId,
      descuentoNombre: ventaData.descuentoNombre,
      montoDescuento: ventaData.montoDescuento,
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
        .map((e) => _mapearDesdeDatos(e.venta, e.nombreCliente))
        .toList();
  }

  @override
  Future<List<Venta>> listarCotizaciones({
    DateTime? desde,
    DateTime? hasta,
    int? clienteId,
    int? usuarioId,
  }) async {
    final resultados = await _ventasDao.listarCotizaciones(
      desde: desde,
      hasta: hasta,
      clienteId: clienteId,
      usuarioId: usuarioId,
    );
    return resultados
        .map(
          (e) => _mapearDesdeDatos(
            e.venta,
            e.nombreCliente,
            esCotizacion: true,
          ),
        )
        .toList();
  }

  @override
  Future<Venta?> obtenerVentaPorId(int ventaId) async {
    final e = await _ventasDao.obtenerVentaPorId(ventaId);
    if (e == null) return null;
    return _mapearDesdeDatos(e, null);
  }

  @override
  Future<Venta?> obtenerVentaBorradorPorId(int cotizacionId) async {
    final e = await _ventasDao.obtenerVentaPorId(cotizacionId);
    if (e == null) return null;
    return _mapearDesdeDatos(e, null, esCotizacion: true);
  }

  @override
  Future<Venta> registrarVenta(Venta venta) async {
    final ventaId = await _ventasDao.insertarVenta(
      VentasTableCompanion(
        clienteId: Value(venta.clienteId),
        fecha: Value(venta.fecha),
        numeroCotizacion: Value(venta.numeroCotizacion),
        numeroFactura: Value(venta.numeroFactura),
        montoSubtotal: Value(venta.montoSubtotal),
        descuentoGlobal: Value(venta.descuentoGlobal),
        itbis: Value(venta.itbis),
        montoTotal: Value(venta.montoTotal),
        formaPago: Value(venta.formaPago),
        costoEnvio: Value(venta.costoEnvio),
        abonoInicial: Value(venta.abonoInicial),
        vencimiento: Value(venta.vencimiento),
        estadoDocumento: Value(venta.estadoDocumento.name),
        usuarioId: Value(venta.usuarioId),
        fechaRegistro: Value(venta.fechaRegistro),
        descuentoId: Value(venta.descuentoId),
        descuentoNombre: Value(venta.descuentoNombre),
        montoDescuento: Value(venta.montoDescuento),
      ),
    );
    if (venta.estadoDocumento == EstadoDocumento.enCredito) {
      final montoAbonar = venta.abonoInicial;
      final fechaVence =
          venta.vencimiento ?? venta.fecha.add(const Duration(days: 30));
      await _cuentasCobrarDao.crearCuentaPorVenta(
        clienteId: venta.clienteId,
        ventaId: ventaId,
        montoOriginal: venta.montoTotal,
        montoAbonado: montoAbonar,
        fechaVencimiento: fechaVence,
      );
    }
    return venta.copyWith(id: ventaId);
  }

  @override
  Future<Venta> registrarVentaBorrador(Venta cotizacion) async {
    final ventaId = await _ventasDao.insertarVenta(
      VentasTableCompanion(
        clienteId: Value(cotizacion.clienteId),
        fecha: Value(cotizacion.fecha),
        numeroCotizacion: Value(cotizacion.numeroCotizacion),
        numeroFactura: Value(cotizacion.numeroFactura),
        montoSubtotal: Value(cotizacion.montoSubtotal),
        descuentoGlobal: Value(cotizacion.descuentoGlobal),
        itbis: Value(cotizacion.itbis),
        montoTotal: Value(cotizacion.montoTotal),
        formaPago: Value(cotizacion.formaPago),
        costoEnvio: Value(cotizacion.costoEnvio),
        abonoInicial: Value(cotizacion.abonoInicial),
        vencimiento: Value(cotizacion.vencimiento),
        estadoDocumento: Value(EstadoDocumento.borrador.name),
        usuarioId: Value(cotizacion.usuarioId),
        fechaRegistro: Value(cotizacion.fechaRegistro),
        descuentoId: Value(cotizacion.descuentoId),
        descuentoNombre: Value(cotizacion.descuentoNombre),
        montoDescuento: Value(cotizacion.montoDescuento),
      ),
    );
    return cotizacion.copyWith(
      id: ventaId,
      numeroCotizacion: 'C-$ventaId',
      estadoDocumento: EstadoDocumento.borrador,
    );
  }

  @override
  Future<Venta> actualizarVentaBorrador(Venta cotizacion) async {
    final int id = cotizacion.id!;
    await _ventasDao.actualizarVenta(
      id,
      VentasTableCompanion(
        clienteId: Value(cotizacion.clienteId),
        fecha: Value(cotizacion.fecha),
        numeroCotizacion: Value(cotizacion.numeroCotizacion),
        numeroFactura: Value(cotizacion.numeroFactura),
        montoSubtotal: Value(cotizacion.montoSubtotal),
        descuentoGlobal: Value(cotizacion.descuentoGlobal),
        itbis: Value(cotizacion.itbis),
        montoTotal: Value(cotizacion.montoTotal),
        formaPago: Value(cotizacion.formaPago),
        costoEnvio: Value(cotizacion.costoEnvio),
        abonoInicial: Value(cotizacion.abonoInicial),
        vencimiento: Value(cotizacion.vencimiento),
        estadoDocumento: Value(cotizacion.estadoDocumento.name),
        usuarioId: Value(cotizacion.usuarioId),
        descuentoId: Value(cotizacion.descuentoId),
        descuentoNombre: Value(cotizacion.descuentoNombre),
        montoDescuento: Value(cotizacion.montoDescuento),
      ),
    );
    return cotizacion;
  }

  @override
  Future<Venta> confirmarVentaBorrador(int cotizacionId) async {
    final cotizacion = await obtenerVentaBorradorPorId(cotizacionId);
    if (cotizacion == null) {
      throw Exception('Cotización no encontrada');
    }
    final ventaConvertida = cotizacion.copyWith(
      numeroCotizacion: cotizacion.numeroCotizacion.replaceFirst('C-', ''),
      estadoDocumento: EstadoDocumento.facturado,
    );
    return await actualizarVentaBorrador(ventaConvertida);
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
    return await _cuentasCobrarDao.obtenerSaldoPorCliente(clienteId);
  }

  @override
  Future<List<Descuento>> obtenerDescuentosActivos() async {
    return const [];
  }

  @override
  Future<List<Oferta>> obtenerOfertasActivas() async {
    return const [];
  }

  @override
  Future<bool> aplicarDescuento(int ventaId, int descuentoId) async {
    return false;
  }

  @override
  Future<bool> validarOferta(int ofertaId, double montoCompra) async {
    return false;
  }

  @override
  Future<void> actualizarEnCascada(int ventaId) async {}
}
